#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Patch dnplayer.exe to disable LDPlayer ad display functions.
Backup already exists: dnplayer.exe.bak
"""
import pefile
import sys

EXE = r"C:\leidian\LDPlayer9\dnplayer.exe"
BAK = r"C:\leidian\LDPlayer9\dnplayer.exe.bak"

# (VA, name, patch_bytes, expect_prefix)
PATCHES = [
    (0x004CE8A0, "_showLaunchAd",          bytes([0xC2, 0x14, 0x00]),         b"\x55\x8b\xec"),
    (0x0044BC30, "canShowAppActiveAD",     bytes([0x31, 0xC0, 0xC2, 0x04, 0x00]), b"\x55\x8b\xec"),
    (0x0044C360, "preShowAppActiveAd",     bytes([0xC2, 0x0C, 0x00]),         b"\x55\x8b\xec"),
    (0x005E1F40, "updateLaunchAdControl",  bytes([0xC3]),                     b"\x55\x8b\xec"),
    (0x004CDF90, "onLaunchAdBtnClicked",   bytes([0xC3]),                     b"\x55\x8b\xec"),
    (0x004CF080, "_checkShowNextLaunchAd", bytes([0xC2, 0x14, 0x00]),         b"\x55\x8b\xec"),
    (0x0044AEE0, "loadAppActiveAd",        bytes([0xC3]),                     b"\x55\x8b\xec"),
    (0x004C7600, "isVideoOK",              bytes([0x31, 0xC0, 0xC3]),         b"\x55\x8b\xec"),
    (0x004C8080, "downloadVid",            bytes([0xC3]),                     b"\x55\x8b\xec"),
]

def rva_to_offset(pe, rva):
    for sec in pe.sections:
        if sec.VirtualAddress <= rva < sec.VirtualAddress + sec.Misc_VirtualSize:
            return rva - sec.VirtualAddress + sec.PointerToRawData
    raise ValueError("RVA 0x%X not in any section" % rva)

def main():
    pe = pefile.PE(EXE)
    image_base = pe.OPTIONAL_HEADER.ImageBase
    data = bytearray(open(EXE, "rb").read())
    done = 0
    for va, name, patch, expect in PATCHES:
        rva = va - image_base
        off = rva_to_offset(pe, rva)
        cur = bytes(data[off:off+len(expect)])
        if not cur.startswith(expect):
            print("SKIP %s @VA 0x%X (off 0x%X): prefix mismatch, got %s" %
                  (name, va, off, cur[:6].hex()))
            continue
        # 记录原字节（输出便于核对）
        orig_len = len(patch) if len(patch) >= 2 else 5  # 覆盖区域统一 ≥5 字节
        # 实际覆盖：新字节 + 用 NOP 填充到原指令边界（此处直接写新字节，余下保留原字节）
        data[off:off+len(patch)] = patch
        # 若原函数以 push ebp; mov ebp,esp 开头且补丁更短，剩余原字节会成为死代码
        # （ret 已提前返回），无需处理。但为整洁，把补丁后至原第5字节填 NOP。
        # 这里保留原始字节即可，因为入口已变成 ret，永远不会执行到。
        print("PATCH %-24s VA 0x%X -> off 0x%X : %s" % (name, va, off, patch.hex()))
        done += 1
    pe.close()
    if done == 0:
        print("ERROR: nothing patched")
        sys.exit(1)
    # 写入：先验证备份存在
    import os
    if not os.path.exists(BAK):
        print("ERROR: backup %s missing" % BAK)
        sys.exit(1)
    with open(EXE, "wb") as f:
        f.write(bytes(data))
    print("WROTE %s (%d patches)" % (EXE, done))

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""只扫 LDPlayer 自有模块，提取完整 http/https URL，区分真实联网域名。"""
import re
import os
import json

FILES = [
    r"C:\leidian\LDPlayer9\dnplayer.exe",
    r"C:\leidian\LDPlayer9\dnplayer-mod.exe",
    r"C:\leidian\LDPlayer9\dnplycore.dll",
    r"C:\leidian\LDPlayer9\dnconsole.exe",
    r"C:\leidian\LDPlayer9\ldconsole.exe",
    r"C:\leidian\LDPlayer9\dnmultiplayer.exe",
    r"C:\leidian\LDPlayer9\dnmultiplayerex.exe",
    r"C:\leidian\LDPlayer9\ldplayerhelper.exe",
    r"C:\leidian\LDPlayer9\ldtool.exe",
    r"C:\leidian\LDPlayer9\ldcam.exe",
    r"C:\leidian\LDPlayer9\ldrecord.exe",
    r"C:\leidian\LDPlayer9\ld.exe",
    r"C:\leidian\LDPlayer9\dnuninst.exe",
    r"C:\leidian\LDPlayer9\ldqqminigame.exe",
    r"C:\leidian\LDPlayer9\ldutils.dll",
    r"C:\leidian\LDPlayer9\ldutils2.dll",
]

# 完整 URL（可含非ASCII则跳过）
url_re = re.compile(rb'https?://[^\x00-\x20\x7f"\']{4,200}')

# 已知非广告服务（证书/文档/更新检查等基础设施，保留）
KEEP = [
    "digicert.com", "globalsign.com", "symantec.com", "verisign.com", "thawte.com",
    "entrust.net", "symcb.com", "symcd.com", "microsoft.com", "virtualbox.org",
    "vmware.com", "openssl.org", "qt-project.org", "w3.org", "whatwg.org",
    "ietf.org", "unicode.org", "ecma-international.org", "apple.com", "webkit.org",
    "chromium.org", "googlesource.com", "crbug.com", "videolan.org", "aomedia.org",
    "dashif.org", "sourceforge.net", "squid-cache.org", "info-zip.org", "curl.haxx.se",
    "curl.se", "iso.org", "gimp.org", "oracle.com", "ibm.com", "iana.org",
    "khronos.org", "oasis-open.org", "jclark.com", "xmlsoft.org", "zlib.net",
    "ejbca.org", "dmtf.org", "winimage.com", "vbox.org",
]

urls = {}  # domain -> [(url, file)]
for f in FILES:
    if not os.path.exists(f):
        continue
    data = open(f, "rb").read()
    for m in url_re.finditer(data):
        u = m.group(0).decode("ascii", "ignore")
        # 规范化截断
        try:
            from urllib.parse import urlsplit
            p = urlsplit(u)
            if not p.hostname:
                continue
            dom = p.hostname.lower()
            # 跳过源码路径误报（.cc/.pro/.cpp 等扩展名当host）
            if dom.endswith((".cc", ".pro", ".cpp", ".h", ".c", ".js", ".ts", ".md", ".json", ".xml", ".png", ".jpg", ".ico", ".css", ".txt", ".net", ".a")):
                continue
            if dom in KEEP:
                continue
            urls.setdefault(dom, set()).add((u[:120], os.path.basename(f)))
        except Exception:
            continue

print("=== 完整 URL 列表（按域名）===")
for dom in sorted(urls):
    print(f"\n[{dom}]")
    for u, fn in sorted(urls[dom]):
        print(f"   {u}   ({fn})")

# 单独：leidian/ldmnq 相关全部出现
print("\n=== ldmnq/leidian 相关 ===")
for dom in sorted(urls):
    if "ldmnq" in dom or "leidian" in dom:
        for u, fn in sorted(urls[dom]):
            print(f"   {u}   ({fn})")
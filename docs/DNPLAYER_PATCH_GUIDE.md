# Windows 客户端启动广告逆向破解指南（dnplayer.exe）

> 本文档补充记录 LDPlayer 9 **Windows 客户端**启动广告的逆向分析与二进制补丁全过程。
> 与 Android 启动器（Launcher3 APK）广告是两个**独立来源**，需分别处理。

## 目录

1. [背景与广告来源](#背景与广告来源)
2. [工具链与环境](#工具链与环境)
3. [逆向分析流程](#逆向分析流程)
4. [核心技术原理](#核心技术原理)
5. [补丁实现方法](#补丁实现方法)
6. [验证与对照测试](#验证与对照测试)
7. [版本切换与备份](#版本切换与备份)

---

## 背景与广告来源

LDPlayer 9 的广告来自两个独立载体，互不影响：

| 广告源 | 载体 | 处理方式 |
|---|---|---|
| Android 桌面启动器广告 | Launcher3 APK | Smali 修改（见 MODIFICATION_GUIDE.md）|
| **Windows 客户端广告** | **dnplayer.exe**（6.8MB, x86 32-bit）| **二进制补丁（本文档）** |

Windows 客户端广告形态：
- 启动加载时的**全屏/横幅广告**
- 应用内**弹窗广告**（AppActive）
- **广告视频**下载播放

宿主进程：`C:\leidian\LDPlayer9\dnplayer.exe`
核心引擎：`C:\Program Files\ldplayer9box\`

> 提示：之前尝试过的 hosts 域名阻断（`ldmnq.com`/`leidian.com` 系）只**部分生效**，
> 部分广告为本地缓存/离线素材，网络阻断无法覆盖 → 必须从二进制层面拦截。

---

## 工具链与环境

| 工具 | 路径 | 用途 |
|---|---|---|
| Ghidra 12.1.4 | `C:\Users\a1\tools\ghidra_12.1.4_PUBLIC` | 静态反汇编/反编译 |
| JDK 21 | `C:\Users\a1\tools\jdk-21.0.2+13` | Ghidra 运行环境 |
| Python 3.14 + pefile | 系统 | PE 结构解析、字节补丁 |
| Ghidra 项目库 | `C:\Users\a1\ldplayer_proj\ldplayer` | 分析结果持久化（含全符号） |

### Ghidra Headless 关键用法

Ghidra 脚本必须放在脚本目录（`Ghidra/Features/Base/ghidra_scripts/`）才能被 headless 执行，
且要用 **Java 脚本**（`.java`）而非 Groovy（需额外插件），PyGhidra 需单独配置：

```bat
set JAVA_HOME=C:\Users\a1\tools\jdk-21.0.2+13
analyzeHeadless.bat C:\Users\a1\ldplayer_proj ldplayer ^
  -process dnplayer.exe -noanalysis -postScript AdRefScan.java
```

### PE 基本信息

```
Machine   : 0x14c (i386, 32-bit)
ImageBase : 0x400000
EntryPoint: 0x2EA900
Sections  : 7（.text RVA=0x1000 RawOffset=0x400）
```

---

## 逆向分析流程

### 第一步：字符串定位（二进制扫描）

在 dnplayer.exe 中直接搜索广告关键字符串（Python + pefile）：

```python
# find_ad_offsets.py 摘要
" _showLaunchAd"   → offset 0x369942, RVA 0x36A542
" canShowAppActiveAD" → offset 0x3592BC, RVA 0x359EBC
" preShowAppActiveAd" → offset 0x359430, RVA 0x35A030
" ADFullScreenFrame" → offset 0x358632, RVA 0x359232
" LDVideoADImpl"   → offset 0x368D9A, RVA 0x36999A
" ad_img_url"      → offset 0x36A9A0, RVA 0x36B5A0
```

### 第二步：RTTI 符号标注（关键突破口）

Ghidra 的 `Windows x86 PE RTTI Analyzer` 自动解析 MSVC RTTI（运行时类型信息），
把每个 C++ 类方法名标注为独立字符串标签（`s_` 前缀）：

```
0076a538  s_LDAdImpl::_showLaunchAd
00759ea4  s_view::ADFullScreenImpl::canShowAppActiveAD
00759994  s_view::LDVideoADImpl::_threadProc
0076a2c8  s_LDAdImpl::updateLaunchAdControl
0076a318  s_LDAdImpl::onLaunchAdBtnClicked
0075a018  s_view::ADFullScreenImpl::preShowAppActiveAd
00759bd8  s_view::ADFullScreenImpl::loadAppActiveAd
0076a644  s_LDAdImpl::_checkShowNextLaunchAd
00769a20  s_view::LDVideoADImpl::isVideoOK
00769b8c  s_view::LDVideoADImpl::downloadVid
```

### 第三步：字符串引用 → 函数本体

RTTI 方法名字符串被函数代码 `push <字符串VA>` 引用（用于日志），
**引用者所在的函数即为该方法的本体**。用 Ghidra 脚本反查引用：

```java
// AdRefScan.java 核心逻辑
Reference[] refs = getReferencesTo(strAddr);  // 字符串地址 → 谁引用它
Function f = getFunctionContaining(ref.getFromAddress());
```

得到方法 → 函数本体映射：

| 方法名 | 函数入口 VA |
|---|---|
| `LDAdImpl::_showLaunchAd` | `0x004CE8A0` |
| `view::ADFullScreenImpl::canShowAppActiveAD` | `0x0044BC30` |
| `view::ADFullScreenImpl::preShowAppActiveAd` | `0x0044C360` |
| `LDAdImpl::updateLaunchAdControl` | `0x005E1F40` |
| `LDAdImpl::onLaunchAdBtnClicked` | `0x004CDF90` |
| `LDAdImpl::_checkShowNextLaunchAd` | `0x004CF080` |
| `view::ADFullScreenImpl::loadAppActiveAd` | `0x0044AEE0` |
| `LDVideoADImpl::_threadProc` | `0x004C7510` |
| `LDVideoADImpl::isVideoOK` | `0x004C7600` |
| `LDVideoADImpl::downloadVid` | `0x004C8080` |

### 第四步：调用链分析

用 Ghidra 脚本反查每个广告函数的**调用者**（`getReferencesTo` 过滤 `isCall()`），
还原广告显示链路：

```
启动广告链：
updateLaunchAdControl (0x005E1F40) ──┐
                                     ├──> _showLaunchAd (0x004CE8A0)   ← 真正显示启动广告
_checkShowNextLaunchAd (0x004CF080) ─┘

全屏/弹窗广告链：
canShowAppActiveAD (0x0044BC30)            ← 判断能否显示（bool）
  └─> preShowAppActiveAd (0x0044C360)      ← 预加载
loadAppActiveAd (0x0044AEE0)               ← 加载广告资源

视频广告链：
LDVideoADImpl::_threadProc (0x004C7510)    ← 下载线程
  └─> downloadVid (0x004C8080)             ← 下载视频
isVideoOK (0x004C7600)                     ← 视频是否就绪（bool）

交互：
onLaunchAdBtnClicked (0x004CDF90)          ← 点击广告跳转
```

### 第五步：确认栈清理字节

补丁函数入口为 `ret` 时必须知道该函数**需要清理多少个栈参数字节**
（决定 `ret N` 的 `N`）。方法：读函数**尾部**的 `RET 0xN` 指令
（MSVC 会生成 `ret N` 形式的栈清理）：

```
_showLaunchAd        @0x004CE8A0 尾 RET 0x14 (20 bytes)
canShowAppActiveAD   @0x0044BC30 尾 RET 0x4  (4 bytes)
preShowAppActiveAd   @0x0044C360 尾 RET 0xc  (12 bytes)
_checkShowNextLaunchAd @0x004CF080 尾 RET 0x14 (20 bytes)
updateLaunchAdControl @0x005E1F40 尾 RET     (0 bytes, __fastcall this in ECX)
onLaunchAdBtnClicked  @0x004CDF90 尾 RET     (0 bytes)
loadAppActiveAd       @0x0044AEE0 尾 RET     (0 bytes)
isVideoOK             @0x004C7600 尾 RET     (0 bytes)
downloadVid           @0x004C8080 尾 RET     (0 bytes)
```

---

## 核心技术原理

### 补丁策略：函数入口短路

原理：把广告函数入口指令改写为 `ret`（返回指令），使函数变成**空函数**，
调用方仍按原约定调用（栈平衡正确），但函数体不再执行任何广告逻辑。

### 指令选择规则

| 场景 | 指令 | 字节 |
|---|---|---|
| void 函数 + 有栈参数 | `ret N`（清 N 字节栈参数）| `C2 NN 00` |
| void 函数 + 无栈参数（fastcall/thiscall，this 在寄存器）| `ret` | `C3` |
| bool 函数 + 有栈参数（恒返回 false）| `xor eax,eax; ret N` | `31 C0 C2 NN 00` |
| bool 函数 + 无栈参数（恒返回 false）| `xor eax,eax; ret` | `31 C0 C3` |

> **为什么必须 `ret N`**：MSVC x86 `__thiscall`/`__stdcall` 由**被调用者**清理栈参数。
> 若入口只写 `ret` 而函数声明了栈参数，返回时栈不平衡 → 调用方崩溃。

> **为什么 bool 函数必须 `xor eax,eax`**：调用方通常 `test eax,eax; jz ...`
> 判断返回值。若直接 `ret` 不清 EAX，返回值是垃圾 → 行为不可控。

---

## 补丁实现方法

### 补丁清单（9 处）

| # | 函数 | VA | 原字节 | 补丁字节 | 效果 |
|---|---|---|---|---|---|
| 1 | `_showLaunchAd` | `0x004CE8A0` | `55 8B EC` | `C2 14 00` | 启动广告不再显示 |
| 2 | `canShowAppActiveAD` | `0x0044BC30` | `55 8B EC` | `31 C0 C2 04 00` | 永远判定"不可显示" |
| 3 | `preShowAppActiveAd` | `0x0044C360` | `55 8B EC` | `C2 0C 00` | 不预加载广告 |
| 4 | `updateLaunchAdControl` | `0x005E1F40` | `55 8B EC` | `C3` | 不触发广告控件更新 |
| 5 | `onLaunchAdBtnClicked` | `0x004CDF90` | `55 8B EC` | `C3` | 广告点击无响应 |
| 6 | `_checkShowNextLaunchAd` | `0x004CF080` | `55 8B EC` | `C2 14 00` | 不检查/触发下次广告 |
| 7 | `loadAppActiveAd` | `0x0044AEE0` | `55 8B EC` | `C3` | 不加载广告资源 |
| 8 | `isVideoOK` | `0x004C7600` | `55 8B EC` | `31 C0 C3` | 视频广告永不"就绪" |
| 9 | `downloadVid` | `0x004C8080` | `55 8B EC` | `C3` | 不下载广告视频 |

所有原字节均为 `55 8B EC`（`push ebp; mov ebp,esp`，标准函数序言）→ 补丁**幂等可校验**。

### 补丁脚本（patch_dnplayer.py）

```python
#!/usr/bin/env python3
"""Patch dnplayer.exe: 9 ad functions -> ret. 幂等，前缀校验。"""
import pefile, sys

EXE = r"C:\leidian\LDPlayer9\dnplayer.exe"

# (VA, 名称, 补丁字节, 期望原字节前缀)
PATCHES = [
    (0x004CE8A0, "_showLaunchAd",          bytes([0xC2,0x14,0x00]),      b"\x55\x8b\xec"),
    (0x0044BC30, "canShowAppActiveAD",     bytes([0x31,0xC0,0xC2,0x04,0x00]), b"\x55\x8b\xec"),
    (0x0044C360, "preShowAppActiveAd",     bytes([0xC2,0x0C,0x00]),      b"\x55\x8b\xec"),
    (0x005E1F40, "updateLaunchAdControl",  bytes([0xC3]),                b"\x55\x8b\xec"),
    (0x004CDF90, "onLaunchAdBtnClicked",   bytes([0xC3]),                b"\x55\x8b\xec"),
    (0x004CF080, "_checkShowNextLaunchAd", bytes([0xC2,0x14,0x00]),      b"\x55\x8b\xec"),
    (0x0044AEE0, "loadAppActiveAd",        bytes([0xC3]),                b"\x55\x8b\xec"),
    (0x004C7600, "isVideoOK",              bytes([0x31,0xC0,0xC3]),      b"\x55\x8b\xec"),
    (0x004C8080, "downloadVid",            bytes([0xC3]),                b"\x55\x8b\xec"),
]

def rva_to_offset(pe, rva):
    for s in pe.sections:
        if s.VirtualAddress <= rva < s.VirtualAddress + s.Misc_VirtualSize:
            return rva - s.VirtualAddress + s.PointerToRawData
    raise ValueError("RVA 0x%X out of sections" % rva)

def main():
    pe = pefile.PE(EXE)
    ib = pe.OPTIONAL_HEADER.ImageBase
    data = bytearray(open(EXE, "rb").read())
    done = 0
    for va, name, patch, expect in PATCHES:
        off = rva_to_offset(pe, va - ib)
        cur = bytes(data[off:off+len(expect)])
        if not cur.startswith(expect):
            print("SKIP %s: prefix mismatch %s" % (name, cur[:6].hex())); continue
        data[off:off+len(patch)] = patch
        print("PATCH %-24s VA 0x%X -> off 0x%X : %s" % (name, va, off, patch.hex()))
        done += 1
    pe.close()
    if done == 0: sys.exit("nothing patched")
    # 写入前确认备份存在
    if not os.path.exists(BAK): sys.exit("backup missing")
    open(EXE, "wb").write(bytes(data))
    print("WROTE %s (%d patches)" % (EXE, done))
```

### 执行步骤

```bat
:: 1. 退出 LDPlayer（dnplayer.exe 占用会 PermissionError）
taskkill /F /IM dnplayer.exe /T

:: 2. 备份（首次）
copy /y C:\leidian\LDPlayer9\dnplayer.exe C:\leidian\LDPlayer9\dnplayer.exe.bak

:: 3. 打补丁
python patch_dnplayer.py

:: 4. 验证字节在位
python -c "import pefile; ..."   （或再跑一次脚本，幂等：全是 SKIP 即已打上）

:: 5. 启动测试
start C:\leidian\LDPlayer9\dnplayer.exe
```

---

## 验证与对照测试

### 字节级验证

补丁后重新解析 PE：

```
PATCH 9/9 全部命中，前缀校验通过
PE machine: 0x14c sections: 7 ALL_OK   ← 结构未被破坏
```

### 运行时验证

- ✅ 修改版启动：进程稳定（PID 存活 10s+），无崩溃、无报错
- ✅ 主窗口正常创建（有 MainWindowTitle）
- ✅ 内存占用正常（~100MB，与原始版一致）

### 对照测试（关键）

用**原始版**（`dnplayer.exe.bak`）和**修改版**（`dnplayer-mod.exe`）交替测试，
验证广告差异确实由补丁引起：

| 版本 | 启动广告 | 全屏/弹窗广告 | 视频广告 |
|---|---|---|---|
| 原始版（bak）| ❌ 有 | ❌ 有 | ❌ 有 |
| 修改版（mod）| ✅ 无 | ✅ 无 | ✅ 无 |

> ⚠️ 对照测试前**先还原 hosts**（之前网络阻断会干扰判断），
> 且注意 `ad.ldmnq.com` 等域名本身对裸连返回 000（服务器侧屏蔽），
> 以 `api.ldmnq.com`（200 可通）作为网络已还原的判据。

---

## 版本切换与备份

### 文件清单

| 文件 | 说明 |
|---|---|
| `dnplayer-mod.exe` | **修改版**（9 处补丁，无广告）|
| `dnplayer.exe` | 当前在用的可执行文件 |
| `dnplayer.exe.bak` | 原始版备份（与 mod 同尺寸 6,807,528 字节）|

### 切换命令

```bat
:: 用修改版
copy /y C:\leidian\LDPlayer9\dnplayer-mod.exe C:\leidian\LDPlayer9\dnplayer.exe

:: 还原原始版（对照测试）
copy /y C:\leidian\LDPlayer9\dnplayer.exe.bak C:\leidian\LDPlayer9\dnplayer.exe
```

⚠️ 切换前先 `taskkill /F /IM dnplayer.exe`。

---

## 网络层阻断（hosts，纵深防御）

> 二进制补丁是主方案，hosts 仅作**纵深防御**（防止广告资源被下载/预取）。
> 原始版经 hosts 阻断后仍残留部分广告（本地缓存素材），补丁版完全无广告。

### 当前阻断清单（16 条，已验证生效）

```
# ldmnq.com 系（12 条）
0.0.0.0 ad.ldmnq.com
0.0.0.0 partner.ldmnq.com
0.0.0.0 api.ldmnq.com
0.0.0.0 www.ldmnq.com
0.0.0.0 res.ldmnq.com
0.0.0.0 mnq-service.ldmnq.com
0.0.0.0 middledata.ldmnq.com
0.0.0.0 service.ldmnq.com
0.0.0.0 cdn.ldmnq.com
0.0.0.0 activity-service.ldmnq.com   ← 活动/广告服务（扫描补充）
0.0.0.0 dist.ldmnq.com               ← 商店推广下载（扫描补充）
0.0.0.0 ldq-service.ldmnq.com        ← 云同步回调（扫描补充）

# leidian.com 系（4 条）
0.0.0.0 ad.leidian.com
0.0.0.0 partner.leidian.com
0.0.0.0 cdn.leidian.com
0.0.0.0 push.leidian.com
```

修改后 `ipconfig /flushdns` 生效。

### 域名扫描方法（找漏网域名）

用 Python 全量扫描 LDPlayer 自有模块中的完整 URL，过滤基础设施域名
（digicert/symantec/verisign/virtualbox/microsoft 等证书与虚拟化服务）：

```python
# scan_focus_urls.py 核心
url_re = re.compile(rb'https?://[^\x00-\x20\x7f"\']{4,200}')
# 只扫 dnplayer.exe / dnplycore.dll / dnconsole.exe / ldplayerhelper.exe 等自有模块
# KEEP 列表过滤：digicert.com, globalsign.com, symantec.com, verisign.com,
#   entrust.net, microsoft.com, virtualbox.org, vmware.com, openssl.org ...
```

本次扫描发现的 LDPlayer 自有服务域名（全部已阻断）：
`activity-service` / `dist` / `ldq-service` / `middledata` / `mnq-service` /
`res` / `www` / `ad` / `partner` / `api` / `service` / `cdn`（ldmnq.com 系）
+ `ad` / `partner` / `cdn` / `push`（leidian.com 系）。

---

## 快速定位方法总结（复用于新版）

LDPlayer 升级后函数地址会漂移，但方法名（RTTI 字符串）是稳定的锚点：

```
1. 二进制搜 "showLaunchAd" / "canShowAppActiveAD" 等字符串 → 拿 RVA
2. Ghidra headless + RTTI Analyzer 跑一遍 → 拿方法名标签地址
3. getReferencesTo(字符串地址) → 反查含引用的函数 → 函数本体入口
4. getReferencesTo(函数入口).isCall() → 调用链
5. 读函数尾部 RET 0xN → 确定补丁 ret N
6. 前缀校验（55 8B EC）→ patch_dnplayer.py 打补丁
7. 原/改版对照测试
```

---

**最后更新**：2026-10-13
**状态**：✅ 已验证通过（用户确认"彻底成功"）
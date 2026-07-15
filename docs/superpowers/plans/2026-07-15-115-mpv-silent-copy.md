# 115 MPV 静默启动与复制直链 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 隐藏 PowerShell/MPV 控制台窗口，并在115视频页增加复用同一原画提取流程的“复制直链”按钮。

**Architecture:** Windows 处理器改用 GUI 版 `mpv.exe`，注册命令以隐藏窗口运行 PowerShell。用户脚本把原画提取拆成一个页面内共享函数，由播放和复制两个按钮调用，并用单个忙碌锁阻止并发。

**Tech Stack:** Tampermonkey JavaScript、Node.js `assert`、Windows PowerShell、HKCU URL 协议、MPV。

## Global Constraints

- Chrome 外部协议首次确认由用户勾选“始终允许”，脚本不绕过浏览器安全确认。
- 不显示 PowerShell 或 `mpv.com` 控制台窗口。
- 只复制 HTTPS `.m3u8` 地址，不复制 Cookie 或令牌。
- 两个按钮不得并发提取，不增加第三方依赖。

---

### Task 1: 静默协议处理器

**Files:**
- Modify: `mpv115-handler.ps1`
- Modify: `install-mpv115-handler.ps1`
- Modify: `test-mpv115-handler.js`

**Interfaces:**
- Consumes: `mpv115://play?...`。
- Produces: 隐藏 PowerShell 且调用 `C:\Users\mugon\Documents\PythonStudio\MyMPV\mpv.exe` 的当前用户协议。

- [ ] **Step 1: Write the failing test**

```javascript
assert(handler.includes("MyMPV\\mpv.exe"));
assert(!handler.includes("MyMPV\\mpv.com"));
assert(installer.includes("-WindowStyle Hidden"));
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node test-mpv115-handler.js`

Expected: FAIL because the handler still contains `mpv.com` and the registry command lacks hidden-window mode.

- [ ] **Step 3: Write minimal implementation**

Change the fixed executable to:

```powershell
$mpv = 'C:\Users\mugon\Documents\PythonStudio\MyMPV\mpv.exe'
```

Register the command as:

```powershell
Set-Item -Path "$root\shell\open\command" -Value ('powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" "%1"' -f $handler)
```

- [ ] **Step 4: Run targeted and full tests**

Run: `node test-mpv115-handler.js`

Run: `Get-ChildItem test-*.js | ForEach-Object { node $_.FullName; if ($LASTEXITCODE) { exit $LASTEXITCODE } }`

Expected: both commands exit 0.

- [ ] **Step 5: Commit**

```bash
git add mpv115-handler.ps1 install-mpv115-handler.ps1 test-mpv115-handler.js
git commit -m "fix: launch MPV without console windows"
```

### Task 2: 共享提取与复制按钮

**Files:**
- Modify: `javbus-larger-thumbnails.user.js`
- Modify: `test-115-mpv-button.js`

**Interfaces:**
- Produces: `extract115OriginalStream(): Promise<string>`；“MPV 原画”和“复制直链”按钮调用它。

- [ ] **Step 1: Write the failing test**

```javascript
assert(source.includes("function extract115OriginalStream"));
assert(source.includes("复制直链"));
assert(source.includes('GM_setClipboard(stream)'));
assert(source.includes("直链已复制"));
assert(source.includes("let busy = false"));
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node test-115-mpv-button.js`

Expected: FAIL because the shared extraction function and copy button are missing.

- [ ] **Step 3: Write minimal implementation**

Move the existing play/select/wait/pause flow into:

```javascript
async function extract115OriginalStream() {
    let video = document.querySelector("video");
    if (!video) throw new Error("找不到网页播放器");
    let before = new Set(get115M3u8Entries());
    let playing = video.play();
    try {
        await select115Original();
        await playing;
        let stream = await waitFor115M3u8(before, 5000);
        if (!stream) throw new Error("未捕获到原画地址");
        return stream;
    } finally {
        video.pause();
    }
}
```

Create both buttons beside “下载”. Each click checks and sets one `busy` boolean, calls the shared function, then either launches `mpv115://play?...` or runs:

```javascript
GM_setClipboard(stream);
showAlert("直链已复制");
```

The `finally` block restores both buttons and clears `busy`.

- [ ] **Step 4: Run targeted and full tests**

Run: `node test-115-mpv-button.js`

Run: `node --check javbus-larger-thumbnails.user.js`

Run: `Get-ChildItem test-*.js | ForEach-Object { node $_.FullName; if ($LASTEXITCODE) { exit $LASTEXITCODE } }`

Expected: all commands exit 0.

- [ ] **Step 5: Commit**

```bash
git add javbus-larger-thumbnails.user.js test-115-mpv-button.js
git commit -m "feat: copy 115 original stream links"
```

### Task 3: Reinstall and verify

**Files:**
- Verify only.

- [ ] **Step 1: Reinstall the protocol**

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-mpv115-handler.ps1`

Expected: registered command contains `-WindowStyle Hidden` and installed handler hash matches the repository file.

- [ ] **Step 2: Reinstall the Tampermonkey script**

Serve the single `.user.js` from `127.0.0.1`, open its standard Tampermonkey reinstall page, and ask the user to confirm only if Chrome blocks control of the extension page.

- [ ] **Step 3: Verify both buttons**

Reload one115 video page. Confirm “MPV 原画” and “复制直链” appear, the copy action yields an HTTPS `.m3u8`, and the MPV action opens only MPV after the user has selected Chrome's “始终允许”.

- [ ] **Step 4: Run final checks**

Run: `Get-ChildItem test-*.js | ForEach-Object { node $_.FullName; if ($LASTEXITCODE) { exit $LASTEXITCODE } }`

Run: `git status --short`

Expected: tests exit 0 and status is clean.

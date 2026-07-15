const fs = require("node:fs");
const assert = require("node:assert");

const handler = fs.readFileSync("mpv115-handler.ps1", "utf8");
const installer = fs.readFileSync("install-mpv115-handler.ps1", "utf8");

assert(handler.includes("mpv115://play"));
assert(handler.includes("https"));
assert(handler.includes("Start-Process"));
assert(handler.includes("--referrer=https://115.com/"));
assert(handler.includes("C:\\Users\\mugon\\Documents\\PythonStudio\\MyMPV\\mpv.com"));
assert(handler.includes("[Math]::Min(160, $title.Length)"));
assert(handler.includes("[Math]::Min(300, $userAgent.Length)"));
assert(!handler.includes("Invoke-Expression"));
assert(!handler.toLowerCase().includes("cookie"));
assert(installer.includes("HKCU:\\Software\\Classes\\mpv115"));
assert(installer.includes("URL Protocol"));
assert(installer.includes("LOCALAPPDATA"), "handler should be installed outside the disposable worktree");
assert(installer.includes("Copy-Item"), "installer should copy the handler to its stable location");

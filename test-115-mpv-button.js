const fs = require("node:fs");
const assert = require("node:assert");

const source = fs.readFileSync("javbus-larger-thumbnails.user.js", "utf8");

assert(source.includes("https://115.com/players/video/*"));
assert(source.includes("function init115MpvPlayback"));
assert(source.includes("function extract115OriginalStream"));
assert(source.includes("MPV 原画"));
assert(source.includes("复制直链"));
assert(source.includes("performance.getEntriesByType"));
assert(source.includes(".m3u8"));
assert(source.includes("mpv115://play?"));
assert(source.includes("video.play()"), "default-paused pages should start one stream request");
assert(source.includes("video.pause()"));
assert(source.includes("GM_setClipboard(stream)"));
assert(source.includes("直链已复制"));
assert(source.includes("let busy = false"));
assert(source.includes("找不到原画控件"));
assert(source.includes("未捕获到原画地址"));
assert(!source.toLowerCase().includes("cookie:"));

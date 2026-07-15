const fs = require("node:fs");
const assert = require("node:assert");

const source = fs.readFileSync("javbus-larger-thumbnails.user.js", "utf8");

assert(source.includes("https://115.com/players/video/*"));
assert(source.includes("function init115MpvPlayback"));
assert(source.includes("function extract115OriginalStream"));
assert(source.includes("MPV 播放"));
assert(source.includes("复制 MPV 链接"));
assert(source.includes("performance.getEntriesByType"));
assert(source.includes(".m3u8"));
assert(source.includes("mpv115://play?"));
assert(source.includes("if (entries.length) return entries[entries.length - 1]"));
assert(source.includes("select115Quality"));
assert(source.includes("findQuality"));
assert(!source.includes("video.play()"), "paused pages must not be started to extract a stream");
assert(!source.includes("video.pause()"), "extraction should not change playback state");
assert(source.includes("function make115ProtocolUrl(stream)"));
assert(source.includes('new URLSearchParams(location.search).get("name")'));
assert(source.includes("GM_setClipboard(make115ProtocolUrl(stream))"));
assert(source.includes("MPV 链接已复制"));
assert(source.includes("let busy = false"));
assert(source.includes("找不到清晰度控件"));
assert(source.includes("未捕获到视频地址"));
assert(!source.toLowerCase().includes("cookie:"));

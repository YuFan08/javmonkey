const fs = require("node:fs");
const assert = require("node:assert");

const source = fs.readFileSync("javbus-larger-thumbnails.user.js", "utf8");

assert(source.includes("function downloadTo115"), "115 downloader function is missing");
assert(source.includes("115.com/web/lixian/?ct=lixian&ac=add_task_urls"), "115 offline endpoint is missing");
assert(source.includes("open115Login"), "115 login fallback is missing");
assert(source.includes("jackett-115-btn"), "Jackett rows need a 115 button");
assert(source.includes("native-115-btn"), "Native magnet rows need a 115 button");
assert(source.includes("url[0]="), "115 request must submit the magnet URL");

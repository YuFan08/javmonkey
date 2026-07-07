const fs = require("node:fs");
const assert = require("node:assert");

const source = fs.readFileSync("javbus-larger-thumbnails.user.js", "utf8");
const guardLine = source.match(/let isJavbusDetail = .+;/)?.[0] || "";

assert(guardLine.includes('$(".bigImage").length > 0'));
assert(guardLine.includes('$(".info").length > 0'));
assert(!guardLine.includes("location.pathname.match"), "JAVBUS Jackett must not start from generic path matches");

const fs = require("node:fs");
const assert = require("node:assert");

const source = fs.readFileSync("javbus-larger-thumbnails.user.js", "utf8");

assert(source.includes('<col class="jackett-col-indexer">'), "Jackett table needs an Indexer column");
assert(source.includes('data-sort="indexer"'), "Indexer header must be sortable");
assert(source.includes('function getJackettIndexer'), "Indexer display should be centralized");
assert(source.includes('item.Tracker || item.Indexer'), "Indexer should come from Jackett result metadata");
assert(source.includes('jackettSort.key === "indexer"'), "Indexer sort branch is missing");assert(source.includes('#jackett-table th:nth-child(5), #jackett-table td:nth-child(5)'), "Action column must be centered after adding Indexer column");
assert(source.includes('<td class="jackett-actions-cell">'), "Action cells need a stable class for alignment");
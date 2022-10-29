const fetch = require("node-fetch");

fetch("https://ipfs.io/ipfs/QmVbZhfYHDyttyPjHQokVHVPYe7Bd5RdUrhxHoE6QimyYs/123")
  .then((response) => response.json())
  .then((json) => console.log(json));

// node scripts/getJson.js

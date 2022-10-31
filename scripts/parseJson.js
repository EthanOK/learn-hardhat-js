const fs = require("fs");
const jsonFile = "./IPFS/json/2.json";

let json1 = {
  name: "You #1",
  description:
    'BFF\'s inaugural collection "You" celebrates the uniqueness of women and non-binary friends across our community and the world. Every NFT has unique perks built in, plus utility within the BFF universe.',
  image: "ipfs://QmZkkoNaKp6PMv6wwy5YqsHvk3EkigUMvhgrmo3SaohZbP/1.png",
  attributes: [
    {
      trait_type: "Background",
      value: "Ambiance",
    },
    {
      trait_type: "Skin Tone",
      value: "Gradient Warm",
    },
    {
      trait_type: "Eyes",
      value: "Orange Eyes",
    },
    {
      trait_type: "Necklace",
      value: "Gold Necklace",
    },
    {
      trait_type: "Clothing",
      value: "Black Tank",
    },
    {
      trait_type: "Hair",
      value: "Black Curly Bob",
    },
    {
      trait_type: "Glasses",
      value: "Tortoise Shell",
    },
    {
      trait_type: "Mouth",
      value: "Red Lipstick",
    },
  ],
};
printJson(json1);
const data = fs.readFileSync(jsonFile, "UTF-8").toString();
let dataJson = JSON.parse(data);
printJson(dataJson);

function printJson(dataJson) {
  console.log("name:" + dataJson.name);
  console.log("description:" + dataJson.description);
  console.log("image:" + dataJson.image);
  console.log("attributes number:" + dataJson.attributes.length);
  for (const attribute of dataJson.attributes) {
    console.log(attribute);
    // console.log(`trait_type: ${attribute.trait_type}`);
    // console.log(`value:${attribute.value}`);
  }
  console.log("----------------------");
}
// node scripts/parseJson.js

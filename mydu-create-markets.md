# Creating markets

## Preparation for markets

In Item hierarchy, make required market elements visible:

- In backoffice, Item Hierarchy, search "Other".
- Set in "Other"'s properties hidden: false .
- Set in (Other's child) "MarketUnit"'s properties hidden: false .
- Make sure all the other children under node "Other" have hidden:true .
- Search marketPodUnit and in it's properties, set hidden: false .

## How to create a new custom market

This procedure creates one market. You can use a construct blueprint or make a custom construct. What makes it a market is that it has Market Unit element and at least one Market Pod, and then some data tweaking in MyDU.

- Claim a hex and set name to something suitable, e.g. "Ion Market 1".
- Deploy a static construct.
- If not yet in construct, Add Market Unid (e.g. size M).
- If not yet in construct,Add all Market Pods and link them to Market Unit.
- Relog
- Try buying something.
- In backoffice go to markets and scroll to last. It should be with name "My Market". Note first column ID.
- At bottom, in "Batch parameter update" enter Market ID, owner 3, Name as you want, and put 0 to all taxes and fees. This will update the name of the market.
- To add the market to planet's POIs, go to constructs on backoffice and find your construct. In Elements tab seach "core". Open the core element and in properties select "gameplayTag", set it's value to "tag_location_marketplace", and click "Submit Query".
- If the market should become a "system" market:
  - Using e.g. PGAdmin, open Postgres table "market", search your new market and change column "owner_id" to 3 and update.
  - With e.g. PGAdmin, open Postgres table "territory", search your market hex and change column "expires_at" to 3000-01-01 00:00:00 and update.
  - Go to Territories in backoffice and search your hex. Select it, Overview tab, Edit and change "Player ID" to 2 .  

- If making your own market:
  - Add e.g. "Market" tag to construct.
  - In RDMS make a new policy "actor:All, rights:Use Elements, tag:Market".
- The new market should now NOT have orders. Re-seed markets.

You may prevent market seeding if you build the market as a child construct of another construct. Then the planet is no longer parent of the market and seeding program skips it. If you later want it seeded, add a seed file with parent's id to data/market_orders folder.

If you made a new planet and want the markets seeded, add a seed file with planet's id to data/market_orders folder.

## How to import ready-made markets to a planet

These are ready-made market sets for legacy planets. They use the old "Small Market" building. ![Small Market](./MyDU-ServerCustomization/blueprints/SmallMarket.png) .

The blueprint json is available [here](https://github.com/Helediron/dualuniverse/tree/master/MyDU-ServerCustomization/blueprints/SmallMarketTemplate2.json) . There are six markets per planet. There are no markets on their moons.

Creating markets require first reservation of the hexes, and then importing constructs.

- Pick construct and territory export json files from a folder [here](https://github.com/Helediron/dualuniverse/tree/master/MyDU-ServerCustomization/construct-exports) .
- Reserve hexes for markets. All hexes for a planet are in one file.
  - In backoffice, go to Territories to import them.
  - Scroll down to "Select fixture" on left.
  - Click "Browse..." and select fixture file, e.g. *Market_Feli_Territory_Fixtures.json* .
  - Click "Replace Fixture Territories".
- In backoffice, go to Constructs and import each construct. Note: these are construct exports - not blueprints.
  - Click "Import".
  - Browse one file, e.g. *Market_Feli_01.json*.
  - Set field "Forced Construct id" to a number in format 6PPPMM where P is planet id and M is market number. A sample is e.g. 600501 ( 6 + Feli's id 5 + market number 1, zero-filled: 6 + 005 + 01 = 600501). (Number series 600000 .. 699999 is unused by NQ).
  - Double-check that import file, planet id, and construct id match.
  - Check "Replace if exists".
  - Click "Import".

Note: importing territories trigger three day expiration. With e.g. PGAdmin, open Postgres table "territory", search your market hexes and change column "expires_at" to 3000-01-01 00:00:00 and update.

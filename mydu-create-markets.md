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
  - Go to Territories in backoffice and search your hex. Select it, Overview tab, Edit and change "Player ID" to 2.  
  - Go to Constructs in backoffice and find your construct. In Overview tab, Edit and change "Player ID" to 2. Note the construct ID. Switch to Properties tab and edit:

```txt
      "isFixture": true

      Under "header":  
        "uniqueIdentifier": "planetsMarkets/<CID>_Marketplace_<Planet>_<number>",  
          where <CID> is construction id. Sample:  
          "uniqueIdentifier": "planetsMarkets/123456_Marketplace_Ion_1",

        "folder": "planetsMarkets",  

        "constructIdHint": <CID>,  
          where <CID> is construction id
      Scroll to bottom and press "Save".  
```

- If making your own market:
  - Add e.g. "Market" tag to construct.
  - In RDMS make a new policy "actor:All, rights:Use Elements, tag:Market".
- The new market should now NOT have orders. Re-seed markets.

## How to import ready-made markets to a planet

These are ready-made market sets for legacy planets. They use the old "Small Market" building.

Creating markets require first reservation of the hexes, and then importing constructs.

- Pick construct and territory exports from here: <https://github.com/Helediron/dualuniverse/tree/master/MyDU-ServerCustomization/construct-exports>
- Reserve hexes for markets. All hexes for a planet are in one file.
  - In backoffice, go to Territories to import them.
  - Scroll down to "Select fixture" on left.
  - Click "Browse..." and select fixture file, e.g. *Market_Feli_Territory_Fixtures.json* .
  - Click "Replace Fixture Territories".
- In backoffice, go to Constructs and import each construct. Note: these are construct exports - not blueprints.
  - Click "Import".
  - Browse one file, e.g. *Market_Feli_01.json*.
  - Set Forced Construct id to 6PPPMM, e.g. 600501 ( 6 + Feli's id 5, market number 1, fill zeros: 6 + 005 + 01).
  - Check "Replace if exists".
  - Click "Import".
- In backoffice, go to Territories and modify each reserved territory.
  - Find and select each territory.
  - Click "Edit".
  - Change Owner, Player ID to 2 .
  - Click "Save".

Note: importing territories trigger three day expiration. With e.g. PGAdmin, open Postgres table "territory", search your market hexes and change column "expires_at" to 3000-01-01 00:00:00 and update.

## Locations of old markets

In the list below are snippets from Lua code containing some old market positions. The information is several years old, and just snitched from a flight script. Anything named "xxx Pad" landed on landing pad of a market. Entries NOT named as "xx Pad" are landing spots near a market, on ground. If there is a list of positions inside "taxii", the last of them is closest to a market.

### Feli

Feli locations updated to match construct exports.

```lua
    locations = {
      {
        name = "Feli M01",
        pos = "::pos{0,5,0.5869,178.9424,18371}",
        sectorLeft = 330,
        sectorRight = 290,
        taxii = {"::pos{0,5,0.7118,178.7828,18390.3691}"}
      }, {
        name = "Feli M02",
        pos = "::pos{0,5,1.0577,-92.0922,18384}",
        sectorLeft = 60,
        sectorRight = 20,
        taxii = {"::pos{0,5,1.2612,-91.9882,18413.2578}"}
      }, {
        name = "Feli M03",
        pos = "::pos{0,5,-0.7751,-17.4513,18455.3535}",
        sectorLeft = 40,
        sectorRight = 0,
        taxii = {"::pos{0,5,-0.6937,-17.4304,18450.8398}"}
      }, {
        name = "Feli M04",
        pos = "::pos{0,5,15.6811,25.4256,18472.6602}",
        sectorLeft = 270,
        sectorRight = 250,
        taxii = {"::pos{0,5,15.6866,25.3332,18472.7930}"}
      }, {
        name = "Feli M05",
        pos = "::pos{0,5,-87.1867,-28.3558,18416.7520}",
        sectorLeft = 80,
        sectorRight = 50,
        taxii = {"::pos{0,5,-87.1494,-25.6241,18416.6543}"}
      }, {
        name = "Feli M06",
        pos = "::pos{0,5,85.6824,-29.1127,18414}",
        sectorLeft = 340,
        sectorRight = 310,
        taxii = {"::pos{0,5,85.8266,-31.0682,18413.2500}"}
      }
    },
```

### Ion

```lua
    locations = {
      {
        name = "Ion M01 pad",
        pos = "::pos{0,120,12.5361,171.0106,819.9741}",
        noUnevenGround = true,
        short = true,
        vectors = {50, 140},
        taxii = {"::pos{0,120,12.5961,170.9579,819.9296}"}
      }, {
        name = "Ion M02 pad",
        pos = "::pos{0,120,2.3706,-0.8186,843.4484}",
        noUnevenGround = true,
        short = true,
        vectors = {90, 0},
        taxii = {"::pos{0,120,2.3688,-0.8777,843.2722}"}
      }, {
        name = "Ion M03 pad",
        pos = "::pos{0,120,6.4811,78.2689,1047.4025}",
        noUnevenGround = true,
        short = true,
        vectors = {240, 60},
        taxii = {"::pos{0,120,6.4578,78.1912,1047.4279}"}
      }, {
        name = "Ion M04 pad",
        pos = "::pos{0,120,-14.6254,-73.2697,650.6949}",
        noUnevenGround = true,
        short = true,
        vectors = {130, 220},
        taxii = {"::pos{0,120,-14.5814,-73.2281,650.6681}"}
      }, {
        name = "Ion M05 pad",
        pos = "::pos{0,120,82.9672,-129.7324,895.3900}",
        noUnevenGround = true,
        short = true,
        vectors = {320, 130},
        taxii = {"::pos{0,120,83.0325,-130.0249,895.4057}"}
      }, {
        name = "Ion M06 pad",
        pos = "::pos{0,120,-75.9707,5.2764,611.0638}",
        noUnevenGround = true,
        short = true,
        vectors = {140, 310},
        taxii = {"::pos{0,120,-75.9359,5.0441,611.2839}"}
      }
    },
```

### Lacobus

```lua
    locations = {
      {
        name = "Lacobus M01 pad",
        pos = "::pos{0,100,6.0911,-84.2460,1610}",
        noUnevenGround = true,
        short = true,
        vectors = {180, 340},
        taxii = {"::pos{0,100,6.1268,-84.2604,1610}"}
      }, {
        name = "Lacobus M02 pad",
        pos = "::pos{0,100,-5.8113,-6.3593,1600}",
        noUnevenGround = true,
        short = true,
        vectors = {240, 80},
        taxii = {"::pos{0,100,-5.8482,-6.4052,1600}"}
      }, {
        name = "Lacobus M03",
        pos = "::pos{0,100,-2.0197,95.1251,1552}",
        vectors = {300, 10, 80, 150},
        taxii = {"::pos{0,100,-1.9590,95.2086,1568}"}
      }, {
        name = "Lacobus M04 pad",
        pos = "::pos{0,100,8.5901,-176.2867,728}",
        noUnevenGround = true,
        short = true,
        vectors = {120, 290},
        taxii = {"::pos{0,100,8.5889,-176.3504,730}"}
      }, {
        name = "Lacobus M05 pad",
        pos = "::pos{0,100,83.2042,-141.5175,1615}",
        noUnevenGround = true,
        short = true,
        vectors = {250, 80},
        taxii = {"::pos{0,100,83.1862,-141.8464,1615}"}
      }, {
        name = "Lacobus M06 pad",
        pos = "::pos{0,100,-88.0287,114.7897,860}",
        noUnevenGround = true,
        short = true,
        vectors = {10, 260},
        taxii = {"::pos{0,100,-87.9213,113.0840,862.7916}"}
      }
    },
```

### Symeon

```lua
    locations = {
      {
        name = "Symeon M01",
        pos = "::pos{0,110,2.8583,-174.3244,264.2408}",
        sectorLeft = 80,
        sectorRight = 10,
        taxii = {"::pos{0,110,3.1124,-174.2745,249.5361}"}
      }, {
        name = "Symeon M02",
        pos = "::pos{0,110,-0.6225,88.8496,177.3605}",
        sectorLeft = 260,
        sectorRight = 210,
        taxii = {"::pos{0,110,-0.8623,88.5842,177.7393}"}
      }, {
        name = "Symeon M03",
        pos = "::pos{0,110,18.1946,10.6802,150.4583}",
        sectorLeft = 140,
        sectorRight = 60, 
        taxii = {"::pos{0,110,17.9788,10.8844,157.6026}"}
      }, {
        name = "Symeon M04",
        pos = "::pos{0,110,-26.8167,103.7925,143.1809}",
        sectorLeft = 300,
        sectorRight = 200,
        taxii = {"::pos{0,110,-26.7408,103.4273,171.3073}"}
      }, {
        name = "Symeon M05",
        pos = "::pos{0,110,82.7474,108.0495,122.3341}",
        sectorLeft = 60,
        sectorRight = 320,
        taxii = {"::pos{0,110,82.9471,107.7711,102.7758}"}
      }, {
        name = "Symeon M06",
        pos = "::pos{0,110,-79.6558,96.6815,120.3957}",
        sectorLeft = 10,
        sectorRight = 280,
        taxii = {"::pos{0,110,-79.5619,96.4197,113.7776}"}
      }, {
        name = "Symeon Missions",
        pos = "::pos{0,110,-1.4725,-52.5171,179.3506}",
      }
    },
```

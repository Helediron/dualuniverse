# Creating markets

## Preparation for markets

In Item hierarchy, make required market elements visible:

- In backoffice, Item Hierarchy, search "Other".
- Set in "Other"'s properties hidden: false .
- Set in (Other's child) "MarketUnit"'s properties hidden: false .
- Make sure all the other children under node "Other" have hidden:true .
- Search marketPodUnit and in it's properties, set hidden: false .

## How to create a market

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

## Locations

In the list below are snippets from Lua code containing some old market positions. Anything named "xxx Pad" landed on landing pad of a market.
Entries NOT named as "xx Pad" are landing spots near a market, on ground.
If there is a list of positions inside "taxii", the last of them is closest to a market

### Feli

```lua
    locations = {
      {
        name = "Feli M01",
        pos = "::pos{0,5,0.5869,178.9424,18371}",
        sectorLeft = 0,
        sectorRight = 280,
        taxii = {"::pos{0,5,0.7491,178.7489,18395}"}
      }, {
        name = "Feli M02",
        pos = "::pos{0,5,1.0577,-92.0922,18384}",
        sectorLeft = 80,
        sectorRight = 5,
        taxii = {"::pos{0,5,1.3509,-92.0043,18418}"}
      }, {
        name = "Feli M03",
        pos = "::pos{0,5,-0.8740,-17.6586,18454}",
        vectors = {105, 180, 310, 25},
        taxii = {"::pos{0,5,-0.8309,-17.4960,18458}"}
      }, {
        name = "Feli M04",
        pos = "::pos{0,5,15.7664,25.6039,18475}",
        vectors = {210, 270, 0, 110},
        taxii = {"::pos{0,5,15.4355,25.7264,18476}"}
      }, {
        name = "Feli M05",
        pos = "::pos{0,5,-87.2990,-20.6490,18414}",
        sectorLeft = 330,
        sectorRight = 240,
        taxii = {"::pos{0,5,-87.3008,-24.2722,18406}"}
      }, {
        name = "Feli M06",
        pos = "::pos{0,5,85.6824,-29.1127,18414}",
        sectorLeft = 40,
        sectorRight = 320,
        taxii = {"::pos{0,5,85.8712,-30.8048,18412}"}
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

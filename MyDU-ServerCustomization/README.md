# Customize MyDU item hierarchy

**This is a test. There is no guarantee that this works.**

## Script: up.sh

Improved **scripts/up.sh** script. It waits and checks each container they really have started by trying to connect a port in each container. Starting order is also slightly changed to minimize container panics.

## Script: FixBlueprints.ps1

Updates blueprint files and changes CreatorId to 2 (Aphelia) and all playerId's to 0.
Pass an argument, e.g. *.json to scan something else than \*.blueprint .

## Script: Generate-Markets.ps1

Note: This script requires programming knowledge.

This script generates prices for all tradeable items in MyDU item hierarchy.

- Download items.yaml .
- Optionally run Yaml-Rewriter.ps1 .
- Run the script:

```ps
.\Generate-Markets.ps1 > markets.log
```

Note: The script generates lots of tracing. The command above directs it to a file markets.log . You should inspect the content afterwards.

- Move file markets.csv to MyDU server.
- Replace the content in files mydu/data/market_orders/*.csv with the content from markets.csv

The current implementation has a sample generator function which calculates price from item weight, tier and size. The default implementation generates relatively cheap prices. You can adjust the price by modifying values in $tierTable, $scaleTable, and  $globalMultiplier.

The code also makes one item to a money source. It generates buy orders for e.g. iron scrap with huge price. Set $MoneySourceItem to the name of an item ("IronScrap" by default), or change to e.g. "nocheating!" to disable it.

There is also $fixed_pricing function, which just sets all prices to 42. You can use this function just to generate a full table of items

To make your own version, find $sample_pricing function and follow instructions in comments above it.

The script understands inherited properties in item hierarchy. It only generates price when

- The item is not a parent item (it is nobody's parent).
- Attribute isTradeable is true (the attribute is on the item or inherited from above).
- Attribute hidden is false or non-existent.

Note: Use PowerShell version 7 to run this script. I don't know how backwards-compatible it is.

Inserting the complete list of market orders wil be a slow operation. It would update nearly two million orders. Use the script admin-seed-markets.sh for updating the orders.

## Script: Yaml-Rewriter.ps1

Note: This script requires programming knowledge. Simple changes into yaml files, like changing a value of properties, should be pretty straight-forward with this script. But it has parts that require quite a lot of PowerShell knowledge.

Note: Use PowerShell version 7 to run this script. I don't know how backwards-compatible it is.

The script needs powershell-yaml component from <https://github.com/cloudbase/powershell-yaml>. Install it

```ps
Install-Module powershell-yaml
```

The script reads one YAML file items.yaml (item hierarchy), changes values according to modifier functions, and writes out a modified file items-changed.yaml.

The intention with this script is to make a modified items hierarchy file to allow trying different settings. It always starts from the default export file and writes out a modified version. You should then import it and test. If something goes wrong, import the default items.yaml and start again. Add/delete modifications in the script and try again. Also if you need to reinstall the whole server, you have the changes stored in the script, and you can run them again.

Read the script and make your own copy. The script is a **sample** what could be done, and you should modify it for your own purposes.

- Set input and output files to $INFILE and $OUTFILE
- Add/remove AddSectionModifier or AddPatternModifier functions, or modify existing ones.
- Save the modified script.

The script has a modifiable part where you can write modifier functions for each section in the yaml file.

### AddSectionModifier

There are two types of filters. First looks like this:

```ps
AddSectionModifier "MiningUnit" { param([string]$name, [hashtable]$values) 
  $values.calibrationGracePeriodHours = 7200
  return $values
}
```

It modifies YAML section "MiningUnit", and the name must match exactly. In items.yaml it looks like this:

```yaml
---
MiningUnit:
  parent: IndustryInfrastructure
  displayName: Mining units
  description: Mining Units can be deployed on constructs in appropriate territories in order to extract raw ore from territory tiles. Mining units will need to be regularly calibrated for optimal usage.
  visibilityLOD: 4
  calibrationGracePeriodHours: 72
  isUseable: true
---
```

The code changes one property, calibrationGracePeriodHours, from 72 to a new value 7200 .

Let's assume you want to modify items.yaml, section AsteroidManagerConfig. Copy/paste an existing function to a new, change the section name and remove all old settings. It should initially look like this:

```ps
AddSectionModifier "AsteroidManagerConfig" { param([string]$name, [hashtable]$values) 
  return $values
}
```

This is the starting point. Then add property modifiers. This should extend asteroid lifetimes:

```ps
AddSectionModifier "AsteroidManagerConfig" { param([string]$name, [hashtable]$values)
  $values.lifetimeDays = 30
  return $values
}
```

### AddPatternModifier

Note: This is an advanced feature needing PowerShell and REGEX knowledge.

Second looks like this (shortened):

```ps
AddPatternModifier "^AtmosphericVerticalBooster" { param([string]$name, [hashtable]$values) 
  if (values.maxPower) {
    [int]$values.maxPower = $values.maxPower * 10
  }
  return $values
}
```

The script will modify every YAML section starting with "AtmosphericVerticalBooster". The parameter for AddPatternModifier parameter is **REGEX** pattern.

When the script reads sections it tries to match all pattern modifiers, and runs modifiers wich do match. It matches e.g. *AtmosphericVerticalBoosterXtraSmallMilitary5*, but also e.g. *AtmosphericVerticalBoosterLargeGroup*, which defines a group - not an engine.

If you had pattern modifiers e.g. "^AtmosphericVerticalBooster" and "(Small|Medium)Military", then section *AtmosphericVerticalBoosterXtraSmallMilitary5* will match both, and both modifiers will be applied.

Note that exact match modifier is run after pattern modifiers.

### Using the script

To use the script:

- Make your own copy of the script. Edit the modifier sections. You can freely remova and add new.
- Click Item Hierarchy in backoffice.
- Click Download on top. Save the items.yaml file next to the script.
- Open PowerShell and Run the script. Note: this is tested in PowerShell version 7.

```ps
.\Yaml-Rewriter.ps1 >items.log
```

- Select the items-changed.yaml in backoffice on top and click Update from File.

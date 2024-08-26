# Customize MyDU item hierarchy

**This is a test. There is no guarantee that this works.**

## Script: up.sh

Improved **scripts/up.sh** script. It waits and checks each container they really have started by trying to connect a port in each container. Starting order is also slightly changed to minimize container panics.

## Script: FixBlueprints.ps1

Updates blueprint files and changes CreatorId to 2 (Aphelia) and all playerId's to 0.
Pass an argument, e.g. *.json to scan something else than \*.blueprint .

## Script: Yaml-Rewriter.ps1

Note: Simple changes into yaml files, like changing a value of properties, should be pretty straight-forward with this script. But it has parts that require quite a lot of PowerShell knowledge.

Note: Use PowerShell version 7 to run this script. I don't know how backwards-compatible it is.

The script needs powershell-yaml component from <https://github.com/cloudbase/powershell-yaml>. Install it

```ps
Install-Module powershell-yaml
```

The script reads one YAML file items.yaml (item hierarchy), changes values according to modifier functions, and writes out a modified file items-changed.yaml.

The intention with this script is to allow trying different settings. It always starts from the default export file. If something goes wrong, import the default items.yaml and start again. Add/delete modifications in the script and try again. Also if you need to reinstall the whole server, you have the changes stored in the script, and you can run them again.

Read the script and make your own copy. The script is a sample what could be done, and you should modify it for your own purposes.

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

# Set input and output file
$INFILES = @(".\items.yaml")
$INFILE_2 = ".\items-nord-append.yaml"
if (Test-Path $INFILE_2) {
  # Support second file for local additions
  $INFILES += $INFILE_2
}
$OUTFILE = ".\items-nord-changed.yaml"
$BACKUP = ".\old-items-nord-changed.yaml"
if (Test-Path $BACKUP) {
  $lastWrite = (get-item $BACKUP).LastWriteTime
  $timespan = new-timespan -hours 16
  if (((get-date) - $lastWrite) -gt $timespan -or !(Test-Path $OUTFILE)) {
    Write-Output "Removed old backup $BACKUP"
    Remove-Item $BACKUP
    if (Test-Path $OUTFILE) {
      Write-Output "Saving $OUTFILE to backup $BACKUP"
      Rename-Item -Path $OUTFILE -NewName $BACKUP
    }
  }
} elseif (Test-Path $OUTFILE) {
  Write-Output "Saving $OUTFILE to backup $BACKUP"
  Rename-Item -Path $OUTFILE -NewName $BACKUP
}

# DON'T TOUCH CODE BELOW, until modifiable part begins

$subtrees = @{}
$sectionHandlers = @{}
$cloneSections = @{}
$cloneSourceSections = @{}
$cloneHandlers = @{}
$assetAliases = @{}
$patterns = @{}
$treeNodes = @{}

$rootName = "ItemHierarchy"
$treeRoot = @{
  "sectName" = $rootName
  "values"   = @{}
  "children" = [ordered]@{}
  "handlers" = [ordered]@{}
}
$treeNodes[$rootName] = $treeRoot

function VerifySectionParameters($filter, $func, $collection) {
  if (!$filter -or $filter.Length -lt 1) {
    Write-Error "Mising or too short modifier name: $filter ."
    exit 2
  }
  if ($collection.ContainsKey($filter)) {
    Write-Error "Duplicate modifier name: $filter ."
    exit 2
  }  
  if (!$func) {
    Write-Error "Missing modifier function: $filter ."
    exit 4
  }
  $funcType = $func.GetType().Name
  if ($funcType -ne "ScriptBlock") {
    Write-Error "Modifier function is not a script: $filter ."
    exit 5
  }
}  

function addAssetAlias($newName, $name) {
  $assetAliases[$newName] = $name
}
function getAssetAlias($name) {
  $alias = $name
  $count = 0
  while ($count -lt 10 -and $assetAliases.Contains($alias)) {
    $count = $count + 1
    if ($count -ge 10) {
      Write-Error "getAssetAlias recursion $name $alias $count"
    }
    $alias = $assetAliases[$alias]
  }
  return $alias
}
function CloneSection($name, $newName, $func) {
  VerifySectionParameters $newName $func $cloneHandlers
  if ($name -match "[A-Za-z][A-Za-z0-9]*") {
    if ($newName -match "[A-Za-z][A-Za-z0-9]*") {
      # Add plain property names into keyword table for direct access.
      $clones = @()
      if ($cloneSections.ContainsKey($name)) {
        $clones = $cloneSections[$name]
      }
      $clones += $newName
      $cloneSections[$name] = $clones
      $cloneSourceSections[$newName] = $name
      addAssetAlias $newName $name
      $len = $clones.Length

      $cloneHandlers[$newName] = $func
      Write-Output "Copying section $name to $newName $len"
    }
    else {
      Write-Error "Section name <$newName> is not plain YAML property name"
    }
  }
  else {
    Write-Error "Section name <$name> is not plain YAML property name"
  }
}
function AddSectionModifier($filter, $func) {
  VerifySectionParameters $filter  $func $sectionHandlers
  if ($filter -match "[A-Za-z][A-Za-z0-9]*") {
    # Add plain property names into keyword table for direct access.
    $sectionHandlers[$filter] = $func
    Write-Output "Added section modifier $filter"
  }
  else {
    Write-Error "Section modifier name <$filter> is not plain YAML property name"
  }
}
function AddSubtreeModifier($filter, $func) {
  VerifySectionParameters $filter  $func $subtrees
  if ($filter -match "[A-Za-z][A-Za-z0-9]*") {
    # Add plain property names into subtrees table for direct access.
    $subtrees[$filter] = $func
    Write-Output "Added subtree modifier $filter"
  }
  else {
    Write-Error "Subtree modifier name <$filter> is not plain YAML property name"
  }
}
function AddPatternModifier($filter, $func) {
  # Add REGEX to patterns.
  VerifySectionParameters $filter  $func $patterns
  $patterns[$filter] = $func
  Write-Output "Added pattern modifier $filter"
}





# MODIFIABLE CODE STARTS FROM HERE

# Add a function with the name of the section in yaml file
# NO printing etc. in these functions - just assign values

$cloneToUncommon = { param([string]$name, [hashtable]$values) 
  $values.level = 2
  $values.displayName = "Uncommon " + $values.displayName
  $values.assetAlias = getAssetAlias $name
  return $values, $true
}

$cloneToAdvanced = { param([string]$name, [hashtable]$values) 
  $values.level = 3
  $values.displayName = "Advanced " + $values.displayName
  $values.assetAlias = getAssetAlias $name
  return $values, $true
}

$cloneToRare = { param([string]$name, [hashtable]$values) 
  $values.level = 4
  $values.displayName = "Rare " + $values.displayName
  $values.assetAlias = getAssetAlias $name
  return $values, $true
}

$cloneToExotic = { param([string]$name, [hashtable]$values) 
  $values.level = 5
  $values.displayName = "Exotic " + $values.displayName
  $values.assetAlias = getAssetAlias $name
  return $values, $true
}

function generateTierVariations($baseName) {
  $tier2Name = $baseName + "2"
  $tier3Name = $baseName + "3"
  $tier4Name = $baseName + "4"
  $tier5Name = $baseName + "5"
  cloneSection $baseName $tier2Name $cloneToUncommon
  cloneSection $baseName $tier3Name $cloneToAdvanced
  cloneSection $baseName $tier4Name $cloneToRare
  cloneSection $baseName $tier5Name $cloneToExotic
}

generateTierVariations "AirbrakeLarge"
generateTierVariations "AirbrakeMedium"
generateTierVariations "AtmosphericFlap"

generateTierVariations "AdjusterLarge"
generateTierVariations "AdjusterMedium"
generateTierVariations "AdjusterSmall"
generateTierVariations "AdjusterXtraSmall"

generateTierVariations "RetroEngineLarge"
generateTierVariations "RetroEngineMedium"
generateTierVariations "RetroEngine"

generateTierVariations "WingLarge2"
generateTierVariations "WingXLarge2"
generateTierVariations "WingMedium2"
generateTierVariations "WingMedium2Bis"
generateTierVariations "WingXtraSmall2"

generateTierVariations "StabilizerXLarge"
generateTierVariations "StabilizerLarge"
generateTierVariations "StabilizerSmall"
generateTierVariations "StabilizerXtraSmall"

generateTierVariations "AileronLarge2"
generateTierVariations "AileronXLarge2"
#generateTierVariations "AileronShortXLarge2"
#generateTierVariations "AileronShortXXLarge2"
generateTierVariations "AileronShortLarge2"
generateTierVariations "AileronMedium2"
generateTierVariations "AileronShortMedium2"
generateTierVariations "AileronSmall2"
generateTierVariations "AileronShortSmall2"


#generateTierVariations ""


AddSectionModifier "Character" { param([string]$name, [hashtable]$values) 
  $values.talentPointsPerSecond = 100
  $values.nanopackMassMul = 0.001
  $values.nanopackMaxVolume = 400000
  $values.nanopackMaxSlots = 100
  $values.defaultWallet = 2000000000.0
  $values.calibrationChargeMax = 100
  $values.calibrationChargeAtStart = 50
  $values.maxConstructs = 1000
  $values.orgConstructSlots = 1000 
  return $values, $true
}

AddSectionModifier "ArkshipModel" { param([string]$name, [hashtable]$values) 
  $values.displayName = "Arkship on [EU] Nord"
  return $values, $true
}

AddSectionModifier "FeaturesList" { param([string]$name, [hashtable]$values) 
  $values.pvp = $true
  $values.talentTree = $true
  $values.preventExternalUrl = $false
  $values.talentRespec = $true
  #$values.territoryUpkeep = $false
  #$values.miningUnitCalibration = $false
  $values.orgConstructLimit = $false
  $values.deactivateCollidingElements = $false
  $values.allowIndustryOnDynamicConstruct = $true
  $values.allowMarketOnDynamicConstruct = $true
  $values.allowBaseShieldOnStaticConstruct = $true
  return $values, $true
}

AddSectionModifier "FetchConstructConfig" { param([string]$name, [hashtable]$values) 
  $values.hasTimeLimit = $false
  $values.fromPlanetSurface = $true
  $values.delay = "60"
  $values.maxDistance = 400000000.0
  return $values, $true
}


AddSectionModifier "ConstructSpeedConfig" { param([string]$name, [hashtable]$values) 
  $values.maxHeavyLinearSpeedKmH = 40000
  $values.maxHeavyAngularSpeed = 0.3
  return $values, $true
}

AddSectionModifier "MiningConfig" { param([string]$name, [hashtable]$values) 
  $values.maxBattery = 1000
  $values.revealCircleRadius = 0.2
  return $values, $true
}

AddSectionModifier "CoherentConfig" { param([string]$name, [hashtable]$values) 
  $values.imageCDNList = ,"*"
  return $values, $true
}

AddSectionModifier "ConstructGCConfig" { param([string]$name, [hashtable]$values) 
  $values.abandonedConstructDeleteDelayHours = 24
  return $values, $true
}


AddSectionModifier "PVPConfig" { param([string]$name, [hashtable]$values)
  # planetProperties is list of {planetName, atmosphericRadius} hashtables
  # $pprops = $values.planetProperties
  # foreach ($value in $pprops) {
  #   [string] $planetName = $value.planetName
  #   if (! ($planetName.Contains("Moon"))) {
  #     $value.atmosphericRadius = 50000000
  #   }
  # }
  # safeZones is list of one {radius,centerZ,centerY,centerX} hashtable
  $safezones = $values.safeZones
  foreach ($value in $safezones) {
    $value.radius = 110000000
  }
  return $values, $true
}
  
AddSectionModifier "TerritoriesConfig" { param([string]$name, [hashtable]$values) 
  $values.territoryUnitRetrieveCooldown = 60
  $values.orgFirstTerritoryFee = 500
  $values.orgTerritoryFeeFactor = 500
  $values.orgTerritoryFeeExponant = 0
  $values.playerFirstTerritoryFee = 0
  $values.playerTerritoryFeeFactor = 500
  $values.playerTerritoryFeeExponant = 0
  $values.initialExpirationDelayDays = 3
  $values.maxBalanceInFeeDays = 99999
  $values.requisitionDelayDays = 14
  $values.upkeepIntervalDays = 365
  $values.upkeepFee = 500
  return $values, $true
}

AddSectionModifier "Talemai" { param([string]$name, [hashtable]$values) 
  $values.maxStaticAltitude = 200000
  return $values, $true
}

AddSectionModifier "TerritoryUnitBasicSanctuary" { param([string]$name, [hashtable]$values) 
  $values.isTradable = $true
  $values.droppable = $true
  $values.isMovable = $true
  return $values, $true
}

AddPatternModifier "^(Consumable|Part)$" { param([string]$name, [hashtable]$values) 
  $values.keptOnDeath = $true
  return $values, $true
}
  
AddSectionModifier "Part" { param([string]$name, [hashtable]$values) 
  $values.keptOnDeath = $true
  return $values, $true
}

AddSectionModifier "Other" { param([string]$name, [hashtable]$values) 
  # Parent of many other parents. Making this hidden:false for MarketPodUnit, but make sure other, unused children have hidden:true
  $values.hidden = $false
  return $values, $true
}
AddSectionModifier "MarketUnit" { param([string]$name, [hashtable]$values) 
  # Parent of many other parents. Making this hidden:false for MarketPodUnit, but make sure other, unused children have hidden:true
  $values.hidden = $false
  return $values, $true
}
AddSectionModifier "MarketPodUnit" { param([string]$name, [hashtable]$values) 
  # Parent of MarketPod. There is also "FakeMarketPod"
  $values.hidden = $false
  return $values, $true
}


AddSectionModifier "CoreUnitStatic512" { param([string]$name, [hashtable]$values) 
  $values.hidden = $false
  $values.displayName = "Static Core Unit"
  #$values.scale = "xl"
  $values.newPlayerDefaultQty = 0
  $values.unitVolume = 10001.00
  $values.unitMass = 20066.30
  $values.price = 251905
  $values.level = 4
  $values.requiredTalents = ,@{
    name = "StaticCoreUnitExpertise"
    level = 4
  }
  $values.hitpoints = 20710  
  return $values, $true
}

AddSectionModifier "CoreUnitDynamic512" { param([string]$name, [hashtable]$values) 
  $values.hidden = $false
  $values.displayName = "Dynamic Core Unit"
  #$values.scale = "xl"
  $values.newPlayerDefaultQty = 0
  $values.unitVolume = 10001.00
  $values.unitMass = 20066.30
  $values.price = 251905
  $values.level = 4
  $values.requiredTalents = ,@{
    name = "DynamicCoreUnitExpertise"
    level = 4
  }
  $values.hitpoints = 20710
  return $values, $true
}

AddSubtreeModifier "CoreUnit" { param([string]$name, [hashtable]$values)
  $item = $treeNodes[$name]
  if ($item) {
    $children = $item.Children
    if ($children.Count -gt 0) {
      # Not modifying parent objects
      return $values, $false  
    } else {
      if ($values.constructSize -and $values.constructSize -gt 512) {
        $multiplier = $values.constructSize / 512
        $values.hidden = $false
        $values.newPlayerDefaultQty = 0
        $values.unitVolume = 10001.00 * $multiplier
        $values.unitMass = 20066.30 * $multiplier
        $values.price = 251905 * $multiplier
        $values.level = 4
        $values.requiredTalents = ,@{
          name = "DynamicCoreUnitExpertise"
          level = 4
        }
        $values.hitpoints = 20710 * $multiplier
      }
    }
  } else {
    return $values, $false  
  }
  return $values, $true
}


AddSectionModifier "MiningUnit" { param([string]$name, [hashtable]$values) 
  $values.calibrationGracePeriodHours = 7200
  return $values, $true
}

AddPatternModifier "MiningUnitLarge" { param([string]$name, [hashtable]$values) 
  if ($values.maxMiningRate) {
    if ($values.level -eq 1) {
      $values.maxMiningRate = 12000
      $values.runtimeHours = 1
    }
    elseif ($values.level -eq 2) {
      $values.maxMiningRate = 10000
      $values.runtimeHours = 1.5
    }
    elseif ($values.level -eq 3) {
      $values.maxMiningRate = 6000
      $values.runtimeHours = 2
    }
    elseif ($values.level -eq 4) {
      $values.maxMiningRate = 4000
      $values.runtimeHours = 3
    }
    elseif ($values.level -eq 5) {
      $values.maxMiningRate = 3000
      $values.runtimeHours = 4
    }

    $values.calibrationCooldownHour = 0
    $values.pickupCooldownHour = 0
    $values.stopCooldownHour = 0
  }
  return $values, $true
}

AddSectionModifier "BaseItem" { param([string]$name, [hashtable]$values) 
  $values.transferUnitSpeedFactor = 0.01
  return $values, $true
}

AddPatternModifier "Material" { param([string]$name, [hashtable]$values) 
  if ($values.transferUnitSpeedFactor) {
    $values.transferUnitSpeedFactor = $values.transferUnitSpeedFactor / 10
  }
  return $values, $true
}


AddSectionModifier "WarpCellStandard" { param([string]$name, [hashtable]$values) 
  $values.unitMass = 1
  $values.unitVolume = 2
  return $values, $true
}

AddSectionModifier "WarpBeaconUnit" { param([string]$name, [hashtable]$values) 
  $values.maxWarpDistance = 200000000
  $values.cruiseSpeedKmH = 13370000
  return $values, $true
}

AddSectionModifier "ItemContainer" { param([string]$name, [hashtable]$values) 
  $values.nbIndustryPlugIn = 50
  $values.nbIndustryPlugOut = 50
  $values.nbControlPlugOut = 50
  return $values, $true
}

AddSectionModifier "ContainerXXXLOptimised5" { param([string]$name, [hashtable]$values) 
  $values.maxVolume = 5462323
  return $values, $true
}



AddSectionModifier "ControlUnit" { param([string]$name, [hashtable]$values) 
  $values.nbControlPlugOut = 50
  return $values, $true
}

AddSectionModifier "Element" { param([string]$name, [hashtable]$values) 
  $values.maxRestoreCount = 99
  return $values, $true
}

AddSectionModifier "FireworkPalmtreeGold" { param([string]$name, [hashtable]$values) 
  $values.price = 1000000000.0
  return $values, $true
}

AddSectionModifier "ElevatorXSmall" { param([string]$name, [hashtable]$values) 
  $values.max_range = 512
  return $values, $true
}

AddSectionModifier "LightAlien" { param([string]$name, [hashtable]$values) 
  $values.hidden = $false
  return $values, $true
}

AddPatternModifier "^(Aileron|Stabilizer|Wing)XLarge" { param([string]$name, [hashtable]$values) 
  if ($values.hidden) {
    $values.hidden = $false
  }
  #if ($name -match "XXXL") {
  #  $values.scale = "xxxl"
  #} elseif ($name -match "XXL") {
  #  $values.scale = "xxl"
  #} else
  if ($name -match "XL") {
    $values.scale = "xl"
  }

  if ($name -eq "StabilizerXLarge") {
    $values.assetAlias =  "WingXLarge2"
  }
  return $values, $true
}
# Remember recursive asset alias
addAssetAlias "StabilizerXLarge" "WingXLarge2"
  
AddPatternModifier "^RocketEngine" { param([string]$name, [hashtable]$values) 
  if ($values.fuelRate) {
    $values.fuelRate = $values.fuelRate / 20
  }
   return $values, $true
}
  
AddSubtreeModifier "EngineUnit" { param([string]$name, [hashtable]$values)
  $item = $treeNodes[$name]
  if ($item) {
    $children = $item.Children
    if ($children.Count -gt 0) {
      # Not modifying parent objects
      return $values, $false  
    } else {
      if ($values.maxPower) {
        $multiplier = 1
        if ($values.level -eq 2) {
          $multiplier = 1.3
        }
        elseif ($values.level -eq 3) {
          $multiplier = 2.6
        }
        elseif ($values.level -eq 4) {
          $multiplier = 8
        }
        elseif ($values.level -eq 5) {
          $multiplier = 16
        }
        if ($multiplier -gt 1) {
          [int]$values.maxPower = $values.maxPower * $multiplier
          $oldText = ""
          if ($values.subdescription) {
            $oldText = $values.subdescription
            if ($oldText.Length -gt 0) {
              $oldText = $oldText + " "
            }
          }
          $values.subdescription = $oldText + "Max power boosted $multiplier * basic."
        }
      }
      if ($values.fuelRate) {
        # TRy half of boost per tier
        $divider = 1
        if ($values.level -eq 2) {
          $divider = 1.3
        }
        elseif ($values.level -eq 3) {
          $divider = 1.3
        }
        elseif ($values.level -eq 4) {
          $divider = 4.0
        }
        elseif ($values.level -eq 5) {
          $divider = 8.0
        }
        if ($divider -gt 1) {
          [Double]$values.fuelRate = $values.fuelRate / $divider
        }
      }
      if ($values.t50 -and $values.t50 -gt 30) {
        $values.t50 = 30
      }
      # if ($values.t50) {
      #   if ($values.level -eq 2) {
      #     [int]$values.t50 = $values.t50 / 1.2
      #   }
      #   elseif ($values.level -eq 3) {
      #     [int]$values.t50 = $values.t50 / 1.5
      #   }
      #   elseif ($values.level -eq 4) {
      #     [int]$values.t50 = $values.t50 / 2
      #   }
      #   elseif ($values.level -eq 5) {
      #     [int]$values.t50 = $values.t50 / 2.5
      #   }
      # }
      if ($values.hitpoints) {
        $multiplier = 1
        if ($values.level -eq 2) {
          $multiplier = 1.5
        }
        elseif ($values.level -eq 3) {
          $multiplier = 3
        }
        elseif ($values.level -eq 4) {
          $multiplier = 4.5
        }
        elseif ($values.level -eq 5) {
          $multiplier = 6
        }
        if ($multiplier -gt 1) {
          [int]$values.hitpoints = $values.hitpoints * $multiplier
        }
      }
    }
  } else {
    return $values, $false  
  }
  return $values, $true
}

# From appended items
addAssetAlias "Headlight2" "Headlight"


# END OF MODIFIABLE CODE








# DON'T TOUCH CODE BELOW, unless you know what you are doing, that is
Import-Module powershell-yaml

# Helper functions
function printList([string]$indent, [string]$name, $value) {
  if ($value) {
    Write-Output "$indent List: $name"
    $key = 0
    foreach ($item in $value) {
      $key = $key + 1
      $typeName = $item.GetType().Name
      if ($typeName.Contains("List")) {
        printList "$indent  " $key $item
      }
      elseif ($typeName.Contains("Hashtable") -or $typeName.Contains("Ordered")) {
        printTable "$indent  " $key $item
      }
      else {
        $line = '  {0}: {1} {2}' -f $key, $item, $typeName
        Write-Output "$indent   $line"
      }
    }
    Write-Output "$indent ----------------"
  }
  else {
    Write-Output "$indent Table: $name is NULL"
    $tab
  }
}

function printTable([string]$indent, [string]$name, [hashtable]$tab) {
  if ($tab) {
    Write-Output "$indent Table: $name :"
    foreach ($key in $tab.Keys) {
      $value = $tab[$key]
      $typeName = $value.GetType().Name
      if ($typeName.Contains("List")) {
        printList "$indent  " $key $value
      }
      else {
        $line = '  {0}: <{1}> {2}' -f $key, $value, $typeName
        Write-Output "$indent   $line"
      }
    }
    Write-Output "$indent ----------------"
  }
  else {
    Write-Output "$indent Table: $name is NULL."
    $tab
  }
}

function evaluateTree([string]$indent, [hashtable]$item, [hashtable]$parent) {
  if ($item) {
    $iName = $item["sectName"]
    Write-Output "$indent item: $iName :"
    $children = $item.Children
    foreach ($key1 in $children.Keys) {
      $child = $children[$key1]
      $child["parent"] = $item
      evaluateTree "$indent " $child $item
    }
  }
  else {
    Write-Output "$indent Item is NULL."
  }
}
function buildTree() {
  # Read all yaml objects and build item hierarchy tree.
  foreach ($key1 in $allSections.Keys) {
    $sect = $allSections[$key1]
    $pName = $sect["parent"]
    $parent = $null
    Write-Output "Add $key1 p $pName ."
    if ($pName) {
      $parent = $treeNodes[$pName]
      if (!$parent) {
        Write-Output " Sect $key1 Add parent $pName ."
        $parent = @{
          "sectName" = $pName
          "values"   = $sect
          "children" = [ordered]@{}
          "handlers" = [ordered]@{}
        }
        $treeNodes[$pName] = $parent
      }
      else {
        Write-Output " Sect $key1 Found parent $pName ."  
      } 
    }
    else {
      Write-Output " Sect $key1 Add to root ."
      $pName = "ItemHierarchy"
      $parent = $treeRoot
    }

    $item = $treeNodes[$key1]
    if (!$item) {
      Write-Output " Sect add $key1 p $pName ."
      $item = @{
        "sectName" = $key1
        "values"   = $sect
        "children" = [ordered]@{}
        "handlers" = [ordered]@{}
      }
      $treeNodes[$key1] = $item    
    }
    else {
      Write-Output " Sect found $key1 p $pName ."
    }
    if ($parent) {
      $pName2 = $parent["sectName"]
      $pChildren = $parent["children"]
      $cCount = $pChildren.Count
      Write-Output " Add child $key1 p $pName $pName2 $cCount ."
      $pChildren.Add($key1, $item)
    }
    else {
      Write-Output " No parent $key1 p $pName ."
    }
  }
}
function buildModifiers() {

  # Clone handler first.
  foreach ($key1 in $treeNodes.Keys) {
    #Write-Output "Section $key1."
    $item = $treeNodes[$key1]
    $handlers = [ordered]@{}
    $handlers1 = $item["handlers"]
    if ($null -ne $handlers1) {
      foreach ($key2 in $handlers1.Keys) {
        $handlers[$key2] = $handlers1[$key2]
      }
    }

    if ($cloneHandlers[$key1]) {
      # Run cloning processor
      $handlers["C-" + $key1] = $cloneHandlers[$key1]
      $count = $handlers.Count
      Write-Output "Adding  $key1 cloning modifier."
    }
    $count = $handlers.Count
    Write-Output "Section $key1 modifiers: $count ."
    if ($count -gt 0) {
      foreach ($key2 in $handlers.Keys) {
        Write-Output " Modifier: $key2"        
      }
    }

    $item["handlers"] = $handlers
  }

  foreach ($key1 in $treeNodes.Keys) {
    #Write-Output "Section $key1."
    $item = $treeNodes[$key1]
    $handlers = [ordered]@{}
    $handlers1 = $item["handlers"]
    if ($null -ne $handlers1) {
      foreach ($key2 in $handlers1.Keys) {
        $handlers[$key2] = $handlers1[$key2]
      }
    }
    # Find subtree processors. Recurse down children and add the processor to each.
    if ($subtrees[$key1]) {
      # Add the node and all children for processing
      Write-Output "Section $key1 has subtree modifier."
      $func = $subtrees[$key1]

      $sectStack = [ordered]@{}
      $sectStack[$key1] = $true
      while ($sectStack.Count -gt 0) {
        $newSect = [ordered]@{}
        foreach ($key2 in $sectStack.Keys) {
          $newSect[$key2] = $sectStack[$key2]
          $item2 = $treeNodes[$key2]
          if ($null -eq $item2) {
            Write-Output "Missing subtree $key1 section $key2"  
          } else {
            $handlers2 = [ordered]@{}
            $handlers3 = $item2["handlers"]
            if ($null -ne $handlers3) {
              foreach ($key3 in $handlers3.Keys) {
                $handlers2[$key3] = $handlers3[$key3]
              }
            }
            $subkey = "S-" + $key1 + "-" + $key2
            if ($handlers2.Contains($subkey)) {
              Write-Output "Skip dup $key1 subtree handler $subkey in $key2"  
            } else {
              $handlers2[$subkey] = $func
              Write-Output "Adding $key1 subtree handler $subkey to $key2"
            }
            $count = $handlers2.Count
            Write-Output " Section $key2 modifiers: $count ."
            if ($count -gt 0) {
              foreach ($key4 in $handlers2.Keys) {
                Write-Output "  Modifier: $key4"
              }
            }
            $item2["handlers"] = $handlers2
          }
        }
        $sectStack.Clear()

        # Add next level children to stack
        foreach ($key2 in $newSect.Keys) {
          $item3 = $treeNodes[$key2]
          if ($item3) {
            $children = $item3.Children
            if ($children.Count -gt 0) {
              Write-Output "Subtree $key2 children:"
              foreach ($key3 in $children.Keys) {
                Write-Output "  Child $key2/$key3"
                $sectStack[$key3] = $true                  
              }
            }
          }
        }
      }
    }

    # Find pattern processors
    foreach ($pat in $patterns.Keys) {
      if ($key1 -match $pat) {
        $handlers["P-" + $pat] = $patterns[$pat]
        $count = $handlers.Count
        Write-Output "Adding $key1 pattern handler $pat."
      }
    }

    if ($sectionHandlers[$key1]) {
      # Run the exact matching processor last
      $handlers["K-" + $key1] = $sectionHandlers[$key1]
      $count = $handlers.Count
      Write-Output "Adding $key1 section modifier."
    }
    $count = $handlers.Count
    Write-Output "Section $key1 modifiers: $count ."
    if ($count -gt 0) {
      foreach ($key2 in $handlers.Keys) {
        Write-Output " Modifier: $key2"        
      }
    }
    $item["handlers"] = $handlers
  }
}

function processSection($value1, $key1) {

  # Find section processors
  $changes1 = 0
  $log = @()
  if (!$treeNodes.ContainsKey($key1)) {
    $log += " Section $key1 not found in treeNodes"
    return $value1, $changes1, $log
  }
  $item = $treeNodes[$key1]
  $handlers = $item["handlers"]

  $modified1 = [ordered]@{}
  foreach ($key2 in $value1.Keys) {
    $modified1[$key2] = $value1[$key2]
  }
  $count = $handlers.Count
  if ($count -gt 0) {
    # Run the processors.
    $log += printTable "" "Section $key1 has $count modifiers"
    $keystate = [ordered]@{}
    foreach ($key2 in $value1.Keys) {
      $keystate[$key2] = $true
    }

    foreach ($pat in $handlers.Keys) {
      $func = $handlers[$pat]
      $log += printTable "" "Section $key1 modifier $pat start" $modified1  
            
      # Recreate the section with same property order as original, to help diffing the files
      $modified3 = [ordered]@{}
      $modified2, $isModified = Invoke-Command $func -ArgumentList $key1, $modified1
      if (!$isModified) {
        $log += " Modifier $pat done, didn't modify"
        $modified3 = $modified2
      } else {
        $log += " Modifier $pat done, section is modified"
        $changes1 = $changes1 + 1
        foreach ($key2 in $keystate.Keys) {
          if ($modified2.ContainsKey($key2)) {
            if (!$keystate[$key2]) {
              $log += "  Key restored: $key1.$key2"
              $keystate[$key2] = $true
            }

            # Try to maintain original datatype.
            if ($null -eq $value1[$key2]) {
              $newValue1 = $modified2[$key2]
              $log += "  New value: $key1.$key2 <$newValue1>."
              $newValue2 = $newValue1
            } else {
              $oldType = $value1[$key2].GetType().Name
              $newType = $modified2[$key2].GetType().Name
              $newValue1 = $modified2[$key2]
              $newValue2 = $null
              if ($newType -eq $oldType) {
                $newValue2 = $newValue1
              } else {
                if ($oldType -eq "Double") {
                  $newValue2 = [Double]$newValue1
                }
                elseif ($oldType -eq "Int32") {
                  if ($newType -eq "Double") {
                    # Allow change from int to double when new value has significant decimals
                    $rounded = ([Math]::Round($newValue1, 0))
                    $decimals = 0.0
                    if ($rounded -lt $newValue1 ) {
                      $decimals = $newValue1 - $rounded
                    }
                    else {
                      $decimals = $rounded - $newValue1
                    }
                    if ($decimals -lt 0.000000001) {
                      $newValue2 = [Int32]$rounded
                      $log += "    Type change $key2 double to int <$newValue1> to <$newValue2>"
                    }
                    else {
                      $newValue2 = $newValue1
                    }

                  }
                  else {
                    $newValue2 = [Int32]$newValue1
                    $log += "    Type change $key2 $newType to int <$newValue1> to <$newValue2>"
                  }
                }
                else {
                  $newValue2 = $newValue1
                  $log += "    Type change $key2 $oldType to $newType <$newValue1> to <$newValue2>"
                }
              }
            }
            $modified3[$key2] = $newValue2
          }
          elseif ($keystate[$key2]) {
            $log += "  Key removed: $key1.$key2"
            $keystate[$key2] = $false
          }
        }
        foreach ($key2 in $modified2.Keys) {
          if (!$keystate[$key2]) {
            $log += "  Key added: $key1.$key2 <$modified2[$key2]>"
            $modified3[$key2] = $modified2[$key2]
            $keystate[$key2] = $true
          }
        }
      }
      $modified1 = $modified3
      $log += " Modifier $pat done $modified1"
    }
  }
  return $modified1, $changes1, $log
}

function writeYaml($modifiedObj, $doc, $docCount, $changes) {
  $yamlText = ""
  if ($changes -gt 0) {
    $newText = ConvertTo-Yaml $modifiedObj
    $newText = $newText -replace ': ""', ": ''"
    $yamlText = $newText
  } else {
    # No processors found. Keep original
    $yamlText = $doc
  }
  if ($docCount -gt 1) {
    if ($changes -gt 0) {
      Add-Content -Path $OUTFILE "---"
    }
    else {
      # Unchanged doc starts with newline
      Add-Content -NoNewline -Path $OUTFILE "---"
    }
    Add-Content -NoNewline -Path $OUTFILE $yamlText
  }
  else {
    Set-Content -NoNewline -Path $OUTFILE $yamlText
  }
}

# Main
$allSections = [ordered]@{}

foreach ($INFILE in $INFILES) {
  $ymlInfile = Get-Content -Path $INFILE -Raw
  $yamlDocs = $ymlInfile -split '---'

  #Read the yaml file
  foreach ($doc in $yamlDocs) {
    if ($doc -and $doc.Length -gt 5) {
      $yamlObj = ConvertFrom-Yaml -Yaml $doc -Ordered
      foreach ($key1 in $yamlObj.Keys) {
        $sect = $yamlObj[$key1]
        $pName = $sect["parent"]
        Write-Output "Section $key1 p $pName ."

        $allSections[$key1] = $sect
        if ($cloneSections.ContainsKey($key1)) {
          foreach ($newName in $cloneSections[$key1]) {
            Write-Output "Section $key1 cloned to $newName."
            $allSections[$newName] = $sect
          }
        }
      }
    }
  }
}

Write-Output "=========================================="
Write-Output "Building item tree."
buildTree

Write-Output "=========================================="
Write-Output "Evaluate tree."
evaluateTree "" $treeRoot $null
Write-Output "Build modifiers."
buildModifiers

Write-Output "=========================================="
Write-Output "Modify yaml."

Set-Content -Path $OUTFILE ""
$docCount = 0
$writtenSections = [ordered]@{}

foreach ($INFILE in $INFILES) {
  $ymlInfile = Get-Content -Path $INFILE -Raw
  $yamlDocs = $ymlInfile -split '---'



  #Write-Output Sections:
  foreach ($doc in $yamlDocs) {
    if ($doc -and $doc.Length -gt 5) {
      $docCount = $docCount + 1
      $yamlObj = ConvertFrom-Yaml -Yaml $doc -Ordered
      $modifiedObj = [ordered]@{}
      $changes = 0
      $yamlText = ""
      #$newYamlText = ""
      #Write-Output "Yaml doc" $doc
      $keyCount = 0
      $newModifiedSections = @()

      foreach ($key1 in $yamlObj.Keys) {
        #Write-Output "Section $key1."
        if ($writtenSections.Contains($key1)) {
          Write-Error "Section $key1 already written"  
        } else {
          $writtenSections[$key1] = $true
          $keyCount = $keyCount + 1
          $value1 = $yamlObj[$key1]
          $modified1, $changes1, $log1 = processSection $value1 $key1
          $changes = $changes + $changes1
          $modifiedObj[$key1] = $modified1
          Write-Output "Section $key1 processed:"
          foreach ($line in $log1) {
            Write-Output $line
          }
        }

        if ($cloneSections.ContainsKey($key1)) {
          $clones = $cloneSections[$key1]
          $len = $clones.Length
          Write-Output "Processing clones from section $key1 $len :"
          foreach ($newName in $clones) {
            if ($writtenSections.Contains($newName)) {
              Write-Error "Clone section $newName already written"  
            } else {
              $writtenSections[$newName] = $true
              Write-Output "Processing clone $newName from section $key1 $len :"
              $newModifiedObj = [ordered]@{}

              $modified1, $changes1, $log1 = processSection $value1 $newName
              $changes = $changes + $changes1 + 1
              $newModifiedObj[$newName] = $modified1
              Write-Output "Clone section $newName processed:"
              foreach ($line in $log1) {
                Write-Output $line
              }
              $newModifiedSections += $newModifiedObj
            }
          }
        }
      }

      writeYaml $modifiedObj $doc $docCount $changes

      foreach ($newModifiedObj in $newModifiedSections) {
        writeYaml $newModifiedObj $doc $docCount $changes
      }
    }
  }
}

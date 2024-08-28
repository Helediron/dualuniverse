# Set input and output file
$INFILE = ".\items.yaml"
$OUTFILE = ".\items-changed.yaml"


# DON'T TOUCH CODE BELOW, until modifiable part begins
function True { return $true }
function False { return $false }

$keywords = @{}
$patterns = @{}
function VerifySectionParameters($filter, $func) {
  if (!$filter -or $filter.Length -lt 1) {
    Write-Error "Mising or too short modifier name: $filter ."
    exit 2
  }
  if ($keywords.ContainsKey($filter)) {
    Write-Error "Duplicate modifier name: $filter ."
    exit 2
  }
  if (!$func) {
    Write-Error "Missing modifier function: $filter ."
    exit 2
  }
  $funcType = $func.GetType().Name
  if ($funcType -ne "ScriptBlock") {
    Write-Error "Modifier function is not a script: $filter ."
    exit 2
  }
}  

function AddSectionModifier($filter, $func) {
  VerifySectionParameters $filter  $func
  if ($filter -match "[A-Za-z][A-Za-z0-9]*") {
    # Add plain property names into keyword table for direct access.
    $keywords[$filter] = $func
    Write-Output "Added keyword modifier $filter"
  }
  else {
    Write-Error "Modifier name <$filter> is not plain YAML property name"
  }
}
function AddPatternModifier($filter, $func) {
  # Add REGEX to patterns.
  VerifySectionParameters $filter  $func
  $patterns[$filter] = $func
  Write-Output "Added pattern modifier $filter"
}





# MODIFIABLE CODE STARTS FROM HERE

# Add a function with the name of the section in yaml file
# NO printing etc. in these functions - just assign values
AddSectionModifier "Character" { param([string]$name, [hashtable]$values) 
  $values.talentPointsPerSecond = 100
  $values.nanopackMassMul = 0.001
  $values.nanopackMaxVolume = 400000
  $values.nanopackMaxSlots = 64
  $values.defaultWallet = 2000000000.0
  $values.calibrationChargeMax = 100
  $values.calibrationChargeAtStart = 50
  $values.maxConstructs = 100
  $values.orgConstructSlots = 100  
  return $values
}

AddSectionModifier "FeaturesList" { param([string]$name, [hashtable]$values) 
  $values.pvp = False
  $values.talentTree = True
  $values.preventExternalUrl = False
  $values.talentRespec = True
  $values.territoryUpkeep = False
  $values.miningUnitCalibration = False
  $values.orgConstructLimit = False
  $values.deactivateCollidingElements = False
  return $values
}

AddSectionModifier "FetchConstructConfig" { param([string]$name, [hashtable]$values) 
  $values.hasTimeLimit = false
  $values.fromPlanetSurface = true
  $values.delay = "60"
  $values.maxDistance = 4000000
  return $values
}

AddSectionModifier "MiningConfig" { param([string]$name, [hashtable]$values) 
  $values.maxBattery = 1000
  $values.revealCircleRadius = 0.2
  return $values
}

AddSectionModifier "PVPConfig" { param([string]$name, [hashtable]$values)
  # planetProperties is list of {planetName, atmosphericRadius} hashtables
  $pprops = $values.planetProperties
  foreach ($value in $pprops) {
    [string] $planetName = $value.planetName
    if (! ($planetName.Contains("Moon"))) {
      $value.atmosphericRadius = 50000000
    }
  }
  # safeZones is list of one {radius,centerZ,centerY,centerX} hashtable
  $safezones = $values.safeZones
  foreach ($value in $safezones) {
    $value.radius = 1800000000
  }
  return $values
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
  $values.maxBalanceInFeeDays = 999
  $values.requisitionDelayDays = 14
  $values.upkeepIntervalDays = 999
  $values.upkeepFee = 500
  return $values
}
  
AddPatternModifier "^(Consumable|Part)$" { param([string]$name, [hashtable]$values) 
  $values.keptOnDeath = True
  return $values
}
  
AddSectionModifier "Part" { param([string]$name, [hashtable]$values) 
  $values.keptOnDeath = True
  return $values
}
  
AddSectionModifier "MiningUnit" { param([string]$name, [hashtable]$values) 
  $values.calibrationGracePeriodHours = 7200
  return $values
}

AddSectionModifier "BaseItem" { param([string]$name, [hashtable]$values) 
  $values.transferUnitBatchSize = 10
  $values.transferUnitSpeedFactor = 10
  return $values
}

AddPatternModifier "^AtmosphericVerticalBooster" { param([string]$name, [hashtable]$values) 
  if ($values.parent -and $values.parent -match "^AtmosphericVerticalBooster.*Group") {
    if ($values.maxPower) {
      if ($values.level -eq 2) {
        [int]$values.maxPower = $values.maxPower * 1.5
      }
      elseif ($values.level -eq 3) {
        [int]$values.maxPower = $values.maxPower * 2
      }
      elseif ($values.level -eq 4) {
        [int]$values.maxPower = $values.maxPower * 5
      }
      elseif ($values.level -eq 5) {
        [int]$values.maxPower = $values.maxPower * 10
      }
      if ($values.maxAltitude) {
        $values.maxAltitude = $values.maxAltitude + 20
      }
    }
  }
  return $values
}


# END OF MODIFIABLE CODE








# DON'T TOUCH CODE BELOW, unless you know what you are doing, that is

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


$ymlInfile = Get-Content -Path $INFILE -Raw
Set-Content -Path $OUTFILE ""
$yamlDocs = $ymlInfile -split '---'


Import-Module powershell-yaml

#Write-Output Sections:
$docCount = 0
foreach ($doc in $yamlDocs) {
  if ($doc -and $doc.Length -gt 5) {
    $docCount = $docCount + 1
    $yamlObj = ConvertFrom-Yaml -Yaml $doc -Ordered
    $modifiedObj = [ordered]@{}
    $changes = 0
    $yamlText = ""
    #Write-Output "Yaml doc" $doc
    foreach ($key1 in $yamlObj.Keys) {
      Write-Output "Section $key1."

      # Find section processors
      $filters = [ordered]@{}
      foreach ($pat in $patterns.Keys) {
        if ($key1 -match $pat) {
          Write-Output "Section $key1 matches pattern modifier $pat."
          $filters["P-" + $pat] = $patterns[$pat]
        }
      }
      if ($keywords[$key1]) {
        # Run the exact matching processor last
        Write-Output "Section $key1 has section modifier."
        $filters["K-" + $key1] = $keywords[$key1]
      }

      $value1 = $yamlObj[$key1]
      $modified1 = $value1
      if ($filters.Count -gt 0) {
        # Run the processors.
        $changes = $changes + 1
        $modified1 = @{}
        foreach ($key2 in $value1.Keys) {
          $modified1[$key2] = $value1[$key2]
        }
        $keystate = [ordered]@{}
        foreach ($key2 in $value1.Keys) {
          $keystate[$key2] = true
        }

        foreach ($pat in $filters.Keys) {
          $func = $filters[$pat]
          printTable "" "Modifier $pat start" $modified1  
                
          # Recreate the section with same property order as original, to help diffing the files
          $modified2 = Invoke-Command $func -ArgumentList $key1, $modified1
          $modified3 = [ordered]@{}
          foreach ($key2 in $keystate.Keys) {
            if ($modified2.ContainsKey($key2)) {
              if (!$keystate[$key2]) {
                Write-Output "  Key restored: $key1.$key2"
                $keystate[$key2] = $true
              }

              # Try to maintain original datatype.
              $oldType = $value1[$key2].GetType().Name
              $newType = $modified2[$key2].GetType().Name
              $newValue1 = $modified2[$key2]
              $newValue2 = $null
              if ($newType -eq $oldType) {
                $newValue2 = $newValue1
              }
              else {
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
                      Write-Output "    Type change $key2 double to int <$newValue1> to <$newValue2>"
                    }
                    else {
                      $newValue2 = $newValue1
                    }
  
                  }
                  else {
                    $newValue2 = [Int32]$newValue1
                    Write-Output "    Type change $key2 $newType to int <$newValue1> to <$newValue2>"
                  }
                }
                else {
                  $newValue2 = $newValue1
                  Write-Output "    Type change $key2 $oldType to $newType <$newValue1> to <$newValue2>"
                }
              }
              $modified3[$key2] = $newValue2
            }
            elseif ($keystate[$key2]) {
              Write-Output "  Key removed: $key1.$key2"
              $keystate[$key2] = $false
            }
          }
          foreach ($key2 in $modified2.Keys) {
            if (!$keystate[$key2]) {
              Write-Output "  Key added: $key1.$key2"
              $modified3[$key2] = $modified2[$key2]
              $keystate[$key2] = $true
            }
          }
          $modified1 = $modified3
          printTable "" "Modifier $pat done" $modified1  
        }
      }
      $modifiedObj[$key1] = $modified1
    }

    if ($changes -gt 0) {
      $newText = ConvertTo-Yaml $modifiedObj
      $newText = $newText -replace ': ""', ": ''"
      $yamlText = $newText
    }
    else {
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
}
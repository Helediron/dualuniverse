# Set input and output file
$INFILES = @(".\items.yaml")
$INFILE_2 = ".\items-nord-append.yaml"
if (Test-Path $INFILE_2) {
  # Support second file for local additions
  $INFILES += $INFILE_2
}
$OUTFILE = ".\items-nord-changed.yaml"


# DON'T TOUCH CODE BELOW, until modifiable part begins

$subtrees = @{}
$sections = @{}
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

function AddSectionModifier($filter, $func) {
  VerifySectionParameters $filter  $func $sections
  if ($filter -match "[A-Za-z][A-Za-z0-9]*") {
    # Add plain property names into keyword table for direct access.
    $sections[$filter] = $func
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
AddSectionModifier "Character" { param([string]$name, [hashtable]$values) 
  $values.talentPointsPerSecond = 100
  $values.nanopackMassMul = 0.001
  $values.nanopackMaxVolume = 400000
  $values.nanopackMaxSlots = 100
  $values.defaultWallet = 2000000000.0
  $values.calibrationChargeMax = 100
  $values.calibrationChargeAtStart = 50
  $values.maxConstructs = 100
  $values.orgConstructSlots = 100  
  return $values, $true
}

AddSectionModifier "ArkshipModel" { param([string]$name, [hashtable]$values) 
  $values.displayName = "Arkship on [EU] Nord"
  return $values, $true
}

AddSectionModifier "FeaturesList" { param([string]$name, [hashtable]$values) 
  $values.pvp = $false
  $values.talentTree = $true
  $values.preventExternalUrl = $false
  $values.talentRespec = $true
  $values.territoryUpkeep = $false
  $values.miningUnitCalibration = $false
  $values.orgConstructLimit = $false
  $values.deactivateCollidingElements = $false
  return $values, $true
}

AddSectionModifier "FetchConstructConfig" { param([string]$name, [hashtable]$values) 
  $values.hasTimeLimit = $false
  $values.fromPlanetSurface = $true
  $values.delay = "60"
  $values.maxDistance = 400000000.0
  return $values, $true
}

AddSectionModifier "MiningConfig" { param([string]$name, [hashtable]$values) 
  $values.maxBattery = 1000
  $values.revealCircleRadius = 0.2
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
  
AddPatternModifier "^(Consumable|Part)$" { param([string]$name, [hashtable]$values) 
  $values.keptOnDeath = $true
  return $values, $true
}
  
AddSectionModifier "Part" { param([string]$name, [hashtable]$values) 
  $values.keptOnDeath = $true
  return $values, $true
}

<# AddSectionModifier "MarketPodUnit" { param([string]$name, [hashtable]$values) 
  $values.hidden = $false
  return $values, $true
}

AddSectionModifier "CoreUnitStatic512" { param([string]$name, [hashtable]$values) 
  $values.hidden = $false
  $values.displayName = "Static Core Unit"
  $values.scale = "xl"
  $values.newPlayerDefaultQty = 0
  $values.unitVolume = 10001.00
  $values.unitMass = 20066.30
  $values.level = 2
  $values.hitpoints = 20710  
  return $values, $true
}

AddSectionModifier "CoreUnitDynamic512" { param([string]$name, [hashtable]$values) 
  $values.hidden = $false
  $values.displayName = "Dynamic Core Unit"
  $values.scale = "xl"
  $values.newPlayerDefaultQty = 0
  $values.unitVolume = 10001.00
  $values.unitMass = 20066.30
  $values.level = 2
  $values.hitpoints = 20710
  return $values, $true
}
 #>
AddSectionModifier "MiningUnit" { param([string]$name, [hashtable]$values) 
  $values.calibrationGracePeriodHours = 7200
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

AddSectionModifier "ItemContainer" { param([string]$name, [hashtable]$values) 
  $values.nbIndustryPlugIn = 20
  $values.nbControlPlugOut = 20
  return $values, $true
}

AddSectionModifier "ControlUnit" { param([string]$name, [hashtable]$values) 
  $values.nbControlPlugOut = 20
  return $values, $true
}

AddSectionModifier "Element" { param([string]$name, [hashtable]$values) 
  $values.maxRestoreCount = 99
  return $values, $true
}


AddPatternModifier "^(Aileron|Stabilizer|Wing)X.*Large" { param([string]$name, [hashtable]$values) 
  if ($values.hidden) {
    $values.hidden = $false
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
        if ($values.level -eq 2) {
          [int]$values.maxPower = $values.maxPower * 1.3
        }
        elseif ($values.level -eq 3) {
          [int]$values.maxPower = $values.maxPower * 2.6
        }
        elseif ($values.level -eq 4) {
          [int]$values.maxPower = $values.maxPower * 8
        }
        elseif ($values.level -eq 5) {
          [int]$values.maxPower = $values.maxPower * 16
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
        if ($values.level -eq 2) {
          [int]$values.hitpoints = $values.hitpoints * 1.5
        }
        elseif ($values.level -eq 3) {
          [int]$values.hitpoints = $values.hitpoints * 3
        }
        elseif ($values.level -eq 4) {
          [int]$values.hitpoints = $values.hitpoints * 4.5
        }
        elseif ($values.level -eq 5) {
          [int]$values.hitpoints = $values.hitpoints * 6
        }
      }
    }
  } else {
    return $values, $false  
  }
  return $values, $true
}


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

  foreach ($key1 in $treeNodes.Keys) {
    #Write-Output "Section $key1."
    $item = $treeNodes[$key1]
    $handlers = $item["handlers"]

    # Find section processors
    foreach ($pat in $patterns.Keys) {
      if ($key1 -match $pat) {
        Write-Output "Section $key1 matches pattern modifier $pat."
        $handlers["P-" + $pat] = $patterns[$pat]
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
          $subkey = "S-" + $key1 + "-" + $key2
          $item2 = $treeNodes[$key2]
          $handlers2 = $item2["handlers"]
        if ($handlers2.Contains($subkey)) {
            Write-Output "Skip dup subtree $key1 section $key2"  
          } else {
            Write-Output "Adding subtree $key1 section $key2"
        
            $handlers2[$subkey] = $func
            $newSect[$key2] = $sectStack[$key2]
          }
        }
        $sectStack.Clear()

        foreach ($key2 in $newSect.Keys) {
          $item = $treeNodes[$key2]
          if ($item) {
            Write-Output "Subtree $key2 children:"
            $children = $item.Children
            if ($children.Count -gt 0) {
              foreach ($key3 in $children.Keys) {
                Write-Output "  Child $key2/$key3"
                $sectStack[$key3] = $true                  
              }
            }
          }
        }
      }
    }
    if ($sections[$key1]) {
      # Run the exact matching processor last
      Write-Output "Section $key1 has section modifier."
      $handlers["K-" + $key1] = $sections[$key1]
    }
  }
}

# Main
$allSections = [ordered]@{}
$docCount = 0

foreach ($INFILE in $INFILES) {
  $ymlInfile = Get-Content -Path $INFILE -Raw
  $yamlDocs = $ymlInfile -split '---'

  #Read the yaml file
  foreach ($doc in $yamlDocs) {
    if ($doc -and $doc.Length -gt 5) {
      $docCount = $docCount + 1
      $yamlObj = ConvertFrom-Yaml -Yaml $doc -Ordered
      foreach ($key1 in $yamlObj.Keys) {
        $sect = $yamlObj[$key1]
        $pName = $sect["parent"]
        Write-Output "Section $key1 p $pName ."

        $allSections[$key1] = $sect
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
foreach ($INFILE in $INFILES) {
  $ymlInfile = Get-Content -Path $INFILE -Raw
  $yamlDocs = $ymlInfile -split '---'



  #Write-Output Sections:
  foreach ($doc in $yamlDocs) {
    if ($doc -and $doc.Length -gt 5) {
      $yamlObj = ConvertFrom-Yaml -Yaml $doc -Ordered
      $modifiedObj = [ordered]@{}
      $changes = 0
      $yamlText = ""
      #Write-Output "Yaml doc" $doc
      foreach ($key1 in $yamlObj.Keys) {
        #Write-Output "Section $key1."

        # Find section processors
        $item = $treeNodes[$key1]
        $filters = $item["handlers"]

        $value1 = $yamlObj[$key1]
        $modified1 = $value1
        if ($filters.Count -gt 0) {
          # Run the processors.
          $modified1 = @{}
          foreach ($key2 in $value1.Keys) {
            $modified1[$key2] = $value1[$key2]
          }
          $keystate = [ordered]@{}
          foreach ($key2 in $value1.Keys) {
            $keystate[$key2] = $true
          }

          foreach ($pat in $filters.Keys) {
            $func = $filters[$pat]
            printTable "" "Section $key1 modifier $pat start" $modified1  
                  
            # Recreate the section with same property order as original, to help diffing the files
            $modified3 = [ordered]@{}
            $modified2, $isModified = Invoke-Command $func -ArgumentList $key1, $modified1
            if (!$isModified) {
              Write-Output "" " Modifier $pat done, didn't modify"
              $modified3 = $modified2
            } else {
              $changes = $changes + 1
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
            }
            $modified1 = $modified3
            printTable "" " Modifier $pat done" $modified1  
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
}
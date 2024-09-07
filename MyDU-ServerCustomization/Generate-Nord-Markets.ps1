# Set input and output file
$INFILE = ".\items-nord-changed.yaml"
if (!(Test-Path $INFILE)) {
  $INFILE = ".\items.yaml"
}
if (!(Test-Path $INFILE)) {
  Write-Error "Can't find input file $INFILE"
  exit 1
}
$OUTFILE = ".\markets.csv"
Write-Output "Genmerating prices, reading $INFILE, writing $OUTFILE ."


# Modifiable code: data and function to generate price for one item.

# Weight-based pricing:
# Tiers 1..5 multipliers
$tierTable = 0,
1, # Tier 1 factor
1.2, # Tier 2 factor
1.5, # Tier 3 factor
1.7, # Tier 4 factor
2     # Tier 5 factor


# Scale multipliers for each size
$scaleTable = @{
  "xs"    = 1
  "s"     = 1.2
  "m"     = 1.4
  "l"     = 1.6
  "xl"    = 2
  "xxl"   = 2.5
  "xxxl"  = 3
  "xxxxl" = 4
}

$globalMultiplier = 1.0

$weight_pricing =
{
  param([hashtable]$item)

  #Some items have explicit price.
  #$price = $item["price"]
  #if ($price) {
  #  return $price
  #}

  $weight = [Double]$item["unitMass"]
  if (!$weight -or $weight -le 0.0) {
    $weight = 1
  }

  # Find tier and pick factor from table
  $tier = [Int32]$item["level"]
  if ($tier -lt 1 -or !$tier) {
    $tier = 1
  }
  if ($tier -gt 5) {
    $tier = 5
  }
  $tierFactor = [Double]$tierTable[$tier]
  if (!$tierFactor -or $tierFactor -le 0.0) {
    $tierFactor = 1
  }

  # Find size and pick factor from table
  $scale = [String]$item["scale"]
  if (!$scale -or $scale.Length -lt 1) {
    $scale = "s"
  }
  $scale = $scale.ToLower()
  $scaleFactor = [Double]$scaleTable[$scale]
  if (!$scaleFactor -or $scaleFactor -le 0.0) {
    $scaleFactor = 1
  }

  # Calculate the price
  $price = $globalMultiplier * $weight * $tierFactor * $scaleFactor

  # Do some rounding.
  if ($price -gt 10000) {
    $price = ([Math]::Round($price / 100, 0) * 100)
  }
  elseif ($price -gt 100) {
    $price = ([Math]::Round($price, 0))
  }
  else {
    $price = ([Math]::Round($price, 2))
  }

  # $line is just debug data and doesn't affect calculation. It gets printed in caller 
  $line = "$price = $weight, $tier, $tierFactor, $scale, $scaleFactor"
  return $price, $line
}

# Fixed pricing
$fixed_pricing =
{
  param([hashtable]$item)

  $price = 42.0

  $line = "fixed: $price"
  return $price, $line
}


# You can make your own pricing function. Copy the function below and change the name.
# Then go to end of this script and change
#    traverseTreeMarket "" $baseItem $null $weight_pricing
# to
#    traverseTreeMarket "" $baseItem $null $sample_pricing
$sample_pricing =
{
  param([hashtable]$item)

  # Calculate your price to $price.
  $price = 2.0
  $scale = [String]$item["scale"]
  if ($scale -eq "xs") {
    $price = 1.0
  }

  # $line is used for debugging. Set it to whatever you want to see in output.
  $line = "degugging: $price"
  return $price, $line
}

# Select the used pricing function here.
$active_pricing = $weight_pricing

#Make one item as a near infinite mouney source:
$MoneySourceItem = "IronScrap"


# End of customizable code








# No modification below
#Dummy use of sample functions, to get rid of warning about unused code:
$dummy_pricing = $weight_pricing
$dummy_pricing = $fixed_pricing
$dummy_pricing = $sample_pricing
$dummy_pricing = $dummy_pricing ? $dummy_pricing : {}

# Scan the tree and propagate inherited properties

# yaml elements not inherited.
$specialNames = @{
  "parent"           = $true
  "description"      = $true
  "displayName"      = $true
  "customProperties" = $true
}

function evaluateTree([string]$indent, [hashtable]$item, [hashtable]$parent) {
  if ($item) {
    $iName = $item["sectName"]
    Write-Output "$indent item: $iName :"
    $children = $item.Children
    foreach ($key1 in $children.Keys) {
      $child = $children[$key1]
      $child["parent"] = $item
      $itemValues = $item["values"]
      $childValues = $child["values"]
      foreach ($key2 in $itemValues.Keys) {
        if (!$specialNames[$key2]) {
          $iv = $itemValues[$key2]
          if (!$childValues.Contains($key2)) {
            Write-Output "$indent   inh: $iName.$key2 : <$iv>."
            $childValues[$key2] = $iv
          }
          else {
            $cv = $childValues[$key2]
            Write-Output "$indent   mask: $iName.$key2 : <$cv> ($iv)."
          }
        }
      }
      evaluateTree "$indent " $child $item
    }
  }
  else {
    Write-Output "$indent Item is NULL."
  }
}

# Traverse the tree and generate market csv
function traverseTreeMarket([string]$indent, [hashtable]$item, [hashtable]$parent, $func) {
  if ($item) {
    $iName = $item["sectName"]
    #Write-Output "$indent item: $iName :"
    $children = $item.Children
    if ($children.Count -gt 0) {
      foreach ($key1 in $children.Keys) {
        $child = $children[$key1]
        traverseTreeMarket "$indent " $child $item $func
      }
    }
    else {
      $itemValues = $item["values"]
      $isTradable = $itemValues["isTradable"]
      $isHidden = $itemValues["hidden"]
      if ($isTradable -and !$isHidden) {
        $price = 1.0
        if ($func) {
          $iName = $item["sectName"]
          $price, $line = Invoke-Command -ScriptBlock $func -ArgumentList $itemValues
          Write-Output "$indent Pricing: $iName : $price, $line"
        }
        $sellPrice = ([Math]::Round($price, 2))
        $sellAmount = 200000000
        $buyPrice = ([Math]::Round($price * 0.5, 2))
        $buyAmount = 0
        if ($iName -eq $MoneySourceItem) {
          # Make one items to a money source
          $buyPrice = 1000000.0
          $buyAmount = 200000000
        }
        $line = "$iName,$sellAmount,$sellPrice,$buyAmount,$buyPrice"
        Add-Content -Path $OUTFILE $line
      }
    }

  }
  else {
    Write-Output "$indent Item is NULL."
  }
}

# Main loop
$ymlInfile = Get-Content -Path $INFILE -Raw
Set-Content -Path $OUTFILE ""
$yamlDocs = $ymlInfile -split '---'
$allSections = [ordered]@{}

Import-Module powershell-yaml

#Read the yaml file
$docCount = 0
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

$treeNodes = @{}

$rootName = "ItemHierarchy"
$treeRoot = @{
  "sectName" = $rootName
  "values"   = @{}
  "children" = [ordered]@{}
}
$treeNodes[$rootName] = $treeRoot

Write-Output "=========================================="
Write-Output "Building item tree."

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

Write-Output "=========================================="
Write-Output "Evaluate tree."
evaluateTree "" $treeRoot $null

Write-Output "=========================================="
Write-Output "Generate prices."
$baseItem = $treeNodes["BaseItem"]
if ($baseItem) {
  traverseTreeMarket "" $baseItem $null $active_pricing
}
else {
  Write-Output "No BaseItem"
}

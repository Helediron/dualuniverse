# Set input and output file
$INFILE = ".\items-changed.yaml"
if (!(Test-Path $INFILE)) {
  $INFILE = ".\items.yaml"
}
if (!(Test-Path $INFILE)) {
  Write-Error "Can't find input file $INFILE"
  exit 1
}
$OUTFILE = ".\markets.csv"
Write-Output "Genmerating prices, reading $INFILE, writing $OUTFILE ."

# yaml elements not inherited.
$specialNames = @{
  "parent" = $true
  "description" = $true
  "displayName" = $true
  "customProperties" = $true
}
# Helper functions
function buildTree([string]$indent, [hashtable]$item, [hashtable]$parent)  {
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
          } else {
            $cv = $childValues[$key2]
            Write-Output "$indent   mask: $iName.$key2 : <$cv> ($iv)."
          }
        }
      }
      buildTree "$indent " $child $item
    }
  }
  else {
    Write-Output "$indent Item is NULL."
  }
}

function traverseTreeMarket([string]$indent, [hashtable]$item, [hashtable]$parent, $func)  {
  if ($item) {
    $iName = $item["sectName"]
    #Write-Output "$indent item: $iName :"
    $children = $item.Children
    if ($children.Count -gt 0) {
      foreach ($key1 in $children.Keys) {
        $child = $children[$key1]
        traverseTreeMarket "$indent " $child $item $func
      }
    } else {
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
        $buyPrice = ([Math]::Round($price * 0.5, 2))
        $line = "$iName,200000000,$sellPrice,0,$buyPrice"
        Add-Content -Path $OUTFILE $line
      }
    }

  }
  else {
    Write-Output "$indent Item is NULL."
  }
}

# Tiers 1..5 multiplier
$tierTable = 0,
  1,
  1.2,
  1.5,
  1.7,
  2


# Scale multipliers
$scaleTable = @{
  "xs" = 1
  "s" = 1.2
  "m" = 1.4
  "l" = 1.6
  "xl" = 2
  "xxl" = 2.5
  "xxxl" = 3
  "xxxxl" = 4
}
$weight_pricing =
{
  param([hashtable]$item)

  #$price = $item["price"]
  #if ($price) {
  #  return $price
  #}

  $weight = [Double]$item["unitMass"]
  if (!$weight -or $weight -le 0.0) {
    $weight = 1
  }

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

  $scale = [String]$item["scale"]
  if (!$scale -or $scale.Length -lt 1) {
    $scale = "s"
  }
  $scale = $scale.ToLower()

  $scaleFactor = [Double]$scaleTable[$scale]
  if (!$scaleFactor -or $scaleFactor -le 0.0) {
    $scaleFactor = 1
  }


  $price = 1.0 * $weight * $tierFactor * $scaleFactor
  if ($price -gt 10000) {
    $price = ([Math]::Round($price / 100, 0) * 100)
  } elseif ($price -gt 100) {
    $price = ([Math]::Round($price, 0))
  } else {
    $price = ([Math]::Round($price, 2))
  }
  $line = "$price = $weight, $tier, $tierFactor, $scale, $scaleFactor"
  return $price, $line
}

$ymlInfile = Get-Content -Path $INFILE -Raw
Set-Content -Path $OUTFILE ""
$yamlDocs = $ymlInfile -split '---'
$allSections = [ordered]@{}

Import-Module powershell-yaml

#Write-Output Sections:
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
  "values" = @{}
  "children" = [ordered]@{}
}
$treeNodes[$rootName] = $treeRoot

Write-Output "=========================================="
Write-Output "Building item tree."

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
        "values" = $sect
        "children" = [ordered]@{}
      }
      $treeNodes[$pName] = $parent
    } else {
      Write-Output " Sect $key1 Found parent $pName ."  
    } 
  } else {
    Write-Output " Sect $key1 Add to root ."
    $pName = "ItemHierarchy"
    $parent = $treeRoot
  }

  $item = $treeNodes[$key1]
  if (!$item) {
    Write-Output " Sect add $key1 p $pName ."
    $item = @{
      "sectName" = $key1
      "values" = $sect
      "children" = [ordered]@{}
    }
    $treeNodes[$key1] = $item    
  } else {
    Write-Output " Sect found $key1 p $pName ."
  }
  if ($parent) {
    $pName2 = $parent["sectName"]
    $pChildren = $parent["children"]
    $cCount = $pChildren.Count
    Write-Output " Add child $key1 p $pName $pName2 $cCount ."
    $pChildren.Add($key1, $item)
  } else {
    Write-Output " No parent $key1 p $pName ."
  }
}

Write-Output "=========================================="
Write-Output "Traversing tree."
buildTree "" $treeRoot $null

$baseItem = $treeNodes["BaseItem"]
if ($baseItem) {
  traverseTreeMarket "" $baseItem $null $weight_pricing
} else {
  Write-Output "No BaseItem"
}





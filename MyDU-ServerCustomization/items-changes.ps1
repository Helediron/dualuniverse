Function modify($rule) {
    $TempFile = Get-Item items-temp.yaml
	Write-Host $rule, $TempFile.Length
	yq -i "$rule" items-temp.yaml
}

#Change file separators --- temporarily to comments
(Get-Content .\items.yaml -Raw) -replace '(?m)^---$','###-###' > items-temp.yaml

modify('.Character.talentPointsPerSecond = "100"')
modify('.Character.nanopackMassMul = "0.001"')
modify('.Character.nanopackMaxVolume = "400000"')
modify('.Character.nanopackMaxSlots = "64"')
modify('.Character.defaultWallet = "2000000000.0"')
modify('.Character.calibrationChargeMax = "100"')
modify('.Character.calibrationChargeAtStart = "50"')
modify('.Character.maxConstructs = "100"')
modify('.Character.orgConstructSlots = "100"')
modify('.FeaturesList.parent = "GameplayObject"')
modify('.FeaturesList.pvp = "false"')
modify('.FeaturesList.talentTree = "true"')
modify('.FeaturesList.preventExternalUrl = "false"')
modify('.FeaturesList.talentRespec = "true"')
modify('.FeaturesList.territoryUpkeep = "false"')
modify('.FeaturesList.orgConstructLimit = "false"')
modify('.FeaturesList.deactivateCollidingElements = "false"')
modify('.FetchConstructConfig.hasTimeLimit = "false"')
modify('.FetchConstructConfig.fromPlanetSurface = "true"')
modify('.FetchConstructConfig.delay = "60"')
modify('.FetchConstructConfig.maxDistance = "4000000"')
modify('.MiningConfig.maxBattery = "1000"')
modify('.MiningConfig.revealCircleRadius = "0.2"')
#modify('.PVPConfig.planetProperties.[] | select(.planetName != "*Moon*").atmosphericRadius |= "50000000"')
modify('.ReconnectionRewardConfig.reconnectionRewardMoney = "1000000"')
modify('.TerritoriesConfig.territoryUnitRetrieveCooldown = "60"')
modify('.TerritoriesConfig.orgFirstTerritoryFee = "500"')
modify('.TerritoriesConfig.orgTerritoryFeeFactor = "500"')
modify('.TerritoriesConfig.orgTerritoryFeeExponant = "0"')
modify('.TerritoriesConfig.playerFirstTerritoryFee = "0"')
modify('.TerritoriesConfig.playerTerritoryFeeFactor = "500"')
modify('.TerritoriesConfig.playerTerritoryFeeExponant = "0"')
modify('.TerritoriesConfig.initialExpirationDelayDays = "3"')
modify('.TerritoriesConfig.maxBalanceInFeeDays = "999"')
modify('.TerritoriesConfig.requisitionDelayDays = "14"')
modify('.TerritoriesConfig.upkeepIntervalDays = "999"')
modify('.TerritoriesConfig.upkeepFee = "500"')
modify('.Consumable.keptOnDeath = "true"')
modify('.Part.keptOnDeath = "true"')
modify('.MiningUnit.calibrationGracePeriodHours = "7200"')

(Get-Content items-temp.yaml).Replace('###-###', '---') | ? {$_.trim() -ne "" } > items-changed.yaml
Remove-Item items-temp.yaml


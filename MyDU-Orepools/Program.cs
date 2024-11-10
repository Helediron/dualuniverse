using System.Collections.Specialized;
using System.CommandLine;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization.Metadata;

namespace Mydu_Orepools
{
    class Program
    {
        static public Dictionary<string, int> tierMap = [];
        static public List<KeyValuePair<string, int>> tierList = [];

        static public void tierMapAdd(string name, int value) {
            tierList.Add(new KeyValuePair<string, int>(name, value));
            tierMap.Add(name, value);
        }
        static async Task<int> Main(string[] args)
        {
            tierMapAdd("CarbonOre", 1);
            tierMapAdd("IronOre", 1);
            tierMapAdd("SiliconOre", 1);
            tierMapAdd("AluminiumOre", 1);
            tierMapAdd("SodiumOre", 2);
            tierMapAdd("CalciumOre", 2);
            tierMapAdd("ChromiumOre", 2);
            tierMapAdd("CopperOre", 2);
            tierMapAdd("NickelOre", 3);
            tierMapAdd("LithiumOre", 3);
            tierMapAdd("SilverOre", 3);
            tierMapAdd("SulfurOre", 3);
            tierMapAdd("GoldOre", 4);
            tierMapAdd("FluorineOre", 4);
            tierMapAdd("ScandiumOre", 4);
            tierMapAdd("CobaltOre", 4);
            tierMapAdd("NiobiumOre", 5);
            tierMapAdd("ManganeseOre", 5);
            tierMapAdd("VanadiumOre", 5);
            tierMapAdd("TitaniumOre", 5);


            var pathInOption = new Option<string?>(
                name: "--in",
                description: "Original ore pool filename of a planet to read in.",
                parseArgument: result =>
                {
                    if (result.Tokens.Count == 0)
                    {
                        result.ErrorMessage = "Missing file parameter value";
                        return null;
                    }
                    string? filePath = result.Tokens.Single().Value;
                    if (!File.Exists(filePath))
                    {
                        result.ErrorMessage = "File does not exist";
                        return null;
                    }
                    else
                    {
                        return filePath;
                    }
                });
            var pathOutOption = new Option<string?>(
                name: "--out",
                description: "New ore pool filename of a planet to write out.");
            var territoriesOption = new Option<int>(
                name: "--territories",
                description: "Number of terrains on a planet.");
            var hexOption = new Option<int>(
                name: "--hexid",
                description: "Terrain id number on a planet.");
            var amountOption = new Option<int>(
                name: "--amount",
                description: "Amount of ore.");
            var removeZerosOption = new Option<bool>(
                name: "--remove-zeros",
                description: "When defined, removes all territories with zero amounts  from outputfile .",
                getDefaultValue: () => false);


            var rootCommand = new RootCommand("Ore pool modifier");
            var simpleModifyCommand = new Command("simple", "Modify one hex on a planet. Simple option adds given amount to tier 1 ores and half of lower tier on next ones up to tier 5.")
                {
                    pathInOption,
                    pathOutOption,
                    territoriesOption,
                    hexOption,
                    amountOption,
                    removeZerosOption
                };
            rootCommand.AddCommand(simpleModifyCommand);
            simpleModifyCommand.SetHandler(async (pathIn, pathOut, territories, hexid, amount, removeZeros) =>
            {
                await  SimpleModify(pathIn!, pathOut!, territories, hexid, amount, removeZeros);
            },
            pathInOption, pathOutOption, territoriesOption, hexOption, amountOption, removeZerosOption);

            return await rootCommand.InvokeAsync(args);
        }

        internal static async Task SimpleModify(
                string pathIn, string pathOut, int territories, int hexid, int amount, bool removeZeros)
        {
            int tier1Amount = amount;
            amount  /= 2;
            int tier2Amount =  amount;
            amount  /= 2;
            int tier3Amount =  amount;
            amount  /= 2;
            int tier4Amount =  amount;
            amount  /= 2;
            int tier5Amount =  amount;
            int[] tierAmounts = [0, tier1Amount, tier2Amount, tier3Amount, tier4Amount, tier5Amount];

            Console.WriteLine(string.Format("Reading {0},\n Writing {1},\n territories {2}, hexid {3}, amount {4}, removeZeros {5}",
              pathIn, pathOut, territories, hexid, amount, removeZeros));
            string jsontext = await File.ReadAllTextAsync(pathIn);
            if (jsontext == null || jsontext.Length < 2) {
                Console.WriteLine("Missing of empty json file " + pathOut);
                return;
            }
            var root = JsonNode.Parse(jsontext);
            if (root == null) {
                Console.WriteLine("Can't read json.");
                return;
            }
            int errorCount = 0;
            var newOres = new JsonObject();
            if (newOres == null) {
                Console.WriteLine("Can't create new root value set.");
                return;
            }
            foreach (var iOre in tierList) {
                string oreName = iOre.Key;
                var oreValue = root[oreName];
                oreValue ??= new JsonObject();
                if (!tierMap.ContainsKey(oreName)) {
                    Console.WriteLine("Unknown ore: " + oreName);
                    continue;
                }
                int zeroCount = 0;
                int nonZeroCount = 0;
                var oreValues = oreValue.AsObject();
                int indexNow = 0;
                int indexMax = 0;
                int indexContinuousMax = 0;
                bool hexIdFound = false;
                var newValues = new JsonObject();
                if (newValues == null) {
                    Console.WriteLine("Can't create new ore value set.");
                    errorCount++;
                    continue;
                }
                int tier = tierMap[oreName];
                int tierAmount = tierAmounts[tier];

                foreach (var iNode in oreValues) {
                    string nodeName = iNode.Key;
                    var nodeValue = iNode.Value;
                    if (nodeName == null || nodeValue == null) {
                        continue;
                    }
                    int index = -1;
                    try {
                        index = Convert.ToInt32(nodeName);
                    } catch {
                        index = -1;
                        Console.WriteLine("Ore " + oreName + " node not integer: " + nodeName);
                        errorCount++;
                    }
                    int value = -1;
                    try {
                        value = nodeValue.GetValue<int>();
                    } catch {
                        value = -1;
                        Console.WriteLine("Ore " + oreName + " node " + nodeName + " value not integer.");
                        errorCount++;
                    }
                    try {
                        if (index == hexid) {
                            Console.WriteLine(string.Format(" Updating ore {0} node {1} to {2}.", oreName, nodeName, tierAmount));
                            value = tierAmount;
                            hexIdFound = true;
                        } else if (index > hexid && !hexIdFound) {
                            string hexName = hexid.ToString();
                            Console.WriteLine(string.Format(" Inserting ore {0} node {1} to {2}.", oreName, hexName, tierAmount));
                            var newValue = JsonValue.Create(tierAmount);
                            newValues.Add(hexName, newValue);
                            hexIdFound = true;
                        }

                        if (value == 0) {
                            zeroCount++;
                        } else if (value > 0) {
                            nonZeroCount++;
                        }
                        if (value > 0 || !removeZeros) {
                            var newValue = JsonValue.Create(value);
                            newValues.Add(nodeName, newValue);
                        }
                    } catch (Exception ex) {
                            Console.WriteLine("Error modifying ore " + oreName + ": " + ex.Message);
                    }
                    if (index >= 0) {
                        if (index == indexNow) {
                            indexContinuousMax = index;
                            indexNow++;
                        }
                        if (index > indexMax) {
                            indexMax = index;
                        }
                    }
                }
                if (!hexIdFound) {
                    string hexName = hexid.ToString();
                    Console.WriteLine(string.Format(" Inserting ore {0} node {1} to {2}.", oreName, hexName, tierAmount));
                    var newValue = JsonValue.Create(tierAmount);
                    newValues.Add(hexName, newValue);
                    hexIdFound = true;
                }
                Console.WriteLine(string.Format("{0}: max {1} cont {2} zeros {3} nonzeros {4}",
                  oreName, indexMax, indexContinuousMax, zeroCount, nonZeroCount));
                try {
                    newOres.Add(oreName, newValues);
                } catch (Exception ex) {
                        Console.WriteLine("Error modifying ore " + oreName + ": " + ex.Message);
                }
            }
            if (errorCount > 0) {
                Console.WriteLine("Errors occurred, skipping output file.");
            } else {
                try {
                    var options = new JsonSerializerOptions();
                    options.WriteIndented = true;
                    options.TypeInfoResolver = new DefaultJsonTypeInfoResolver();
                    
                    var textOut = newOres.ToJsonString(options);
                    var fileOut = File.CreateText(pathOut);
                    await fileOut.WriteAsync(textOut);
                    await fileOut.FlushAsync();
                    fileOut.Close();
                } catch (Exception ex) {
                    Console.WriteLine("Error writing out file " + pathOut + ": " + ex.Message);
                }
            }
        }
    }
}
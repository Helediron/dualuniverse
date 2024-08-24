# Customize MyDU item hierarchy

**This is a test. There is no guarantee that this works.**

Script: items-changes.ps1

The script changes values in the item hierarchy. It takes a default export from backoffice, modifies it and writes out the modified version.

The intention with this script is to try different settings. It always starts from the default export file. If something goes wrong, import the default items.yaml and start again. Add/delete modifications in the script and try again.

Read the script. Each modify line changes one value in the item hierarchy.

The script uses program yq <https://github.com/mikefarah/yq>. You can install it in windows with

```cmd
winget install --id MikeFarah.yq
```

- Click Item Hierarchy in backoffice.
- Click Download on top. Save the items.yaml file next to the script.
- Run the script.
- Select the items-changed.yaml in backoffice on top and click Update from File.

Script: FixBlueprints.ps1

Updates blueprint files and changes CreatorId to 2 (Aphelia) and all playerId's to 0.
Pass an argument, e.g. *.json to scan something else than \*.blueprint .

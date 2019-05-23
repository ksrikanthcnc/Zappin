# Zappin (Sony Walkman Series' 'zap' feature)

A PowerShell script to implement [Sony Walkman's zappin](http://docs.esupport.sony.com/portable/NWZW262_W263_manual/eng/contents/03/01/06/06.html) feature

### Pre-Requisites
[Enable PowerShell scripts to run on your machine](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-6)
- Open powershell with admin privileges
- Enter `set-executionpolicy remotesigned` and Press `Y` to permanently allow running of powershell scripts

Or to temporarily allow an instance of powershell to allow scripts, open a poershell and run `powershell.exe -ExecutionPolicy bypass` , and then load the script

You can load the script by running `. <path to file>`

### Usage
After loading function(script) (with `. .\zappinps1`)  
`zappin -Path <path> -Shuffle -Loop -zapstart -zap -Duration`  
`-Shuffle` (default false) enables shuffled playback, else sequential  
`-Loop` (default false) enables repeat  
`-zapstart` (default true) start at random position  
`-zap` (default true) play each song for 'Duration' seconds  
`-Duration <seconds in int>` (Default 30) play zap feature for Mentioned seconds  
To get control back to shell use `Ctrl+C`(^C)  
to stop, use `zappin -Stop`  
to resume Verbose(filenames) of player use `zappin -Verbose`

### To-Do
Allow multipe sources

### References
https://github.com/PrateekKumarSingh/MusicPlayer (http://ridicurious.com/2018/04/03/powershell-module-to-play-music/)

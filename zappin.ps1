Function zappin{
    [cmdletbinding()]
    Param(  [Alias('P')]  [String] $Path,
            [Alias('Sh')] [switch] $Shuffle,
            [Alias('St')] [Switch] $Stop,
            [Alias('L')]  [Switch] $Loop,
            [int] $Duration=30,
            [switch] $zap=$true,
            [switch] $zapstart=$true)
    If($Stop){
        Write-Output "Stoping any Already running instance of Media in background."
        Get-Job MusicPlayer -ErrorAction SilentlyContinue | Remove-Job -Force}
    Else{#Play
        #Path cache stuff
        If($path){#Caches Path for next time in case you don't enter path to the music directory
            Write-Output "Entering $path to .\PathCache.txt"
            $Path | Out-File -FilePath .\PathCache.txt}
        else{
            If((cat .\PathCache.txt -ErrorAction SilentlyContinue).Length -ne 0){#Cache exists
                If($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
                    Write-Output "You've not provided a music directory, looking for cached information from Previous use."}
                $path = cat .\PathCache.txt
                If(-not (Test-Path $Path)){#no cache, first-run
                    "Please provide a path to a music directory.`nFound a cached directory `"$Path`" from previous use, but that too isn't accessible!"
                    $Path = '' }} # Mark Path as Empty string, If Cached path doesn't exist
            else{
                Write-Output "Please provide a path to a music directory."}}

        $init = {#Initialization Script
                Write-Output 'Init'
                # Function to calculate duration of song in Seconds
                Function Get-SongDuration($FullName)
                {
                    $Shell = New-Object -COMObject Shell.Application
                    $Folder = $shell.Namespace($(Split-Path $FullName))
                    $File = $Folder.ParseName($(Split-Path $FullName -Leaf))
                    [int]$h, [int]$m, [int]$s = ($Folder.GetDetailsOf($File, 27)).split(":")
                    $h*60*60 + $m*60 +$s
                }

                # Function to Notify Information balloon message in system Tray
                Function Show-NotifyBalloon($Message)
                {
                    [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
                    $Global:Balloon = New-Object System.Windows.Forms.NotifyIcon
                    $Balloon.Icon =  [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $pid | Select-Object -ExpandProperty Path))
                    $Balloon.BalloonTipIcon = 'Info'
                    $Balloon.BalloonTipText = $Message
                    $Balloon.BalloonTipTitle = 'Now Playing'
                    $Balloon.Visible = $true
                    $Balloon.ShowBalloonTip(1000)
                }
                Function PlayMusic($path, $Shuffle, $Loop, $zap, $zapstart, $Duration)
                {   Write-Output 'PlayMusic'
                    # Calling required assembly
                    Add-Type -AssemblyName PresentationCore

                    # Instantiate Media Player Class
                    $MediaPlayer = New-Object System.Windows.Media.Mediaplayer

                    # Crunching the numbers and Information
                    Write-Output 'Preparing PlayList'
                    $FileList = gci $Path -Recurse -Include *.mp* | select fullname, @{n='Duration';e={get-songduration $_.fullname}}
                    $FileCount = $FileList.count
                    $TotalPlayDuration =  [Math]::Round(($FileList.duration | measure -Sum).sum /60)

                    if($Shuffle){
                        $Mode = "Shuffle"
                        $FileList = $FileList | Sort-Object {Get-Random}}
                    Else{
                        $Mode = "Sequential"}

                    # Check If user chose to play songs in Loop
                    If($Loop){
                        $Mode = $Mode + " in Loop"
                        $TotalPlayDuration = "Infinite"}

                    If($FileList){
                        ''| select @{n='TotalSongs';e={$FileCount};},@{n='PlayDuration';e={[String]$TotalPlayDuration + " Mins"}},@{n='Mode';e={$Mode}}}
                    else{
                        Write-Output "No music files found in directory `"$path`" ."}
                    
                    Write-Output "Starting Playback with \nPath=$path \nShuffle:$shuffle \nLoop:$loop \nzap:$zap \nzapstart:$zapstart \nDuration:$Duration"

                    Do{
                        $FileList |%{
                                        $CurrentSongDuration= New-TimeSpan -Seconds (Get-SongDuration $_.fullname)
                                        $Message = "Song : "+$(Split-Path $_.fullname -Leaf)+"`nPlay Duration : $($CurrentSongDuration.Minutes) Mins $($CurrentSongDuration.Seconds) Sec`nMode : $Mode"
                                        # Show-NotifyBalloon ($Message)
                                        $MediaPlayer.Open($_.FullName)
                                        If($zapstart){
                                            $startat = (Get-Random)%((Get-SongDuration $_.fullname)-$Duration)}
                                        Else{
                                            $startat = 0}
                                        $MediaPlayer.Position = New-TimeSpan -Seconds ($startat)
                                        $MediaPlayer.Play()
                                        Write-Output($_.fullname)
                                        If($zap){
                                            Start-Sleep -Seconds $Duration}
                                        Else{
                                            Start-Sleep -Seconds $_.duration}
                                        $MediaPlayer.Stop()
                        }
                    if($Shuffle){
                        Write-Output 'Finished;Re-Shuffling for next PlayList'
                        $FileList = gci $Path -Recurse -Include *.mp* | select fullname, @{n='Duration';e={get-songduration $_.fullname}}
                        $FileList = $FileList | Sort-Object {Get-Random}}
                    }While($Loop) # Play Infinitely If 'Loop' is chosen by user
                }
        }

        # Removes any already running Job, and start a new job, that looks like changing the track
        $Verbose=$PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        If($Verbose){
            while(1){
                Receive-Job -Name MusicPlayer | Out-Host}}
        If(!$Verbose -and $(Get-Job Musicplayer -ErrorAction SilentlyContinue)){
            Get-Job MusicPlayer -ErrorAction SilentlyContinue |Remove-Job -Force}

        # Run only if path was Defined or retrieved from cached information
        If($Path)
        {
            Write-Verbose "Starting a background Job to play Music files"
            Start-Job -Name MusicPlayer -InitializationScript $init -ScriptBlock {playmusic $args[0] $args[1] $args[2] $args[3] $args[4] $args[5] $args[6]} -ArgumentList $path, $Shuffle, $Loop, $zap, $zapstart, $Duration | Out-Null
            Start-Sleep -Seconds 3       # Sleep to allow media player some breathing time to load files
            Receive-Job -Name MusicPlayer | ft @{n='TotalSongs';e={$_.TotalSongs};alignment='left'},@{n='TotalPlayDuration';e={$_.PlayDuration};alignment='left'},@{n='Mode';e={$_.Mode};alignment='left'} -AutoSize | Out-Null
     while(1){
            Receive-Job -Name MusicPlayer | Out-Host}
        }
    }
}

echo "Zappin
Usage:
'zappin -Path <path> -Shuffle -Loop -zapstart -zap -Duration'
-Shuffle (default false) enables shuffled playback, else sequential
-Loop (default false) enabled repeat
-zapstart (default true) start at random position
-zap (default true) play each song for Duration seconds
-Duration <seconds in int> play zap feature for Mentioned seconds
to stop, use 'zappin -Stop'"
# parse guides

class GameInfo
{
    [String]$Name
    [String]$Platform
    [String]$HasGuide
    [String]$HasPlatinum
    [String]$Difficulty
    [String]$TimeToComplete
    [String]$HasOnlineTrophies
    [String]$Genre
    [String]$Release
    [String]$Guide
}

Function Check-FileExists($filePath)
{
    if(-not (Test-Path $filePath))
    {
        throw "Cannot find file: $filePath"
    } 
}

Function Add-GameInfoToFile([GameInfo]$gameInfo, $filePath)
{
    # TODO: add ,$($gameInfo.HasOnlineTrophies) before Genre
    $line = "$($gameInfo.Name),$($gameInfo.Platform),$($gameInfo.HasGuide),$($gameInfo.HasPlatinum),$($gameInfo.Difficulty),$($gameInfo.TimeToComplete),$($gameInfo.HasOnlineTrophies),$($gameInfo.Genre),$($gameInfo.Release),$($gameInfo.Guide)"
    Add-Content -Path $filePath -Value $line -Encoding UTF8
}

Push-Location $PSScriptRoot

[System.Environment]::CurrentDirectory = Get-Location

$cacheFolderName = "cache"
$outputFile = ".\ps-now-games_en-us.csv"
$inPsNow = ".\tmp\ps-now-games_en-us+.txt"
$inManualResolution = ".\customize\manualDifficultyAndTime.txt"

if(Test-Path $outputFile)
{
    Remove-Item -Path $outputFile
}

if(-not (Test-Path $cacheFolderName -PathType Container))
{
    Write-Error "Cannot find cache at: $cacheFolderName"
    return -1
}

Check-FileExists $inPsNow
Check-FileExists $inManualResolution

$psNowGamesFileContent = Get-Content $inPsNow
$psNowGames = New-Object System.Collections.Generic.List[GameInfo]
$psNowGamesCount = 0

Write-Host "Loading list of games..."
foreach($psNowGameEntry in $psNowGamesFileContent)
{
    # comma in name
    $psNowGameEntry = $psNowGameEntry.Replace(", Beelzebub", " Beelzebub")
    $psNowGameEntry = $psNowGameEntry.Replace("Warhammer 40,000", "Warhammer 40000")

    $segments = $psNowGameEntry.Split(",")
    $gameInfo = [GameInfo]::new()
    $gameInfo.Name = $segments[0]
    $gameInfo.Platform = $segments[1]
    $gameInfo.Guide = $segments[2]
    $psNowGames.Add($gameInfo)
}

$inManualResolutionFileContent = Get-Content $inManualResolution
$manualResolution = New-Object 'System.Collections.Generic.Dictionary[string, GameInfo]'

Write-Host "Loading manual resolution..."
foreach($inManualResolutionEntry in $inManualResolutionFileContent)
{
    $segments = $inManualResolutionEntry.Split("|")
    $gameInfo = [GameInfo]::new()
    $gameInfo.Name = $segments[0].Trim()
    $gameInfo.Difficulty = $segments[1].Trim()
    $gameInfo.TimeToComplete = $segments[2].Trim()
    $gameInfo.HasOnlineTrophies = $segments[3].Trim()
    $manualResolution.Add($gameInfo.Name, $gameInfo)
}

Write-Host "Parsing guides..."

Add-Content -Path $outputFile -Value "Name,Platform,HasGuide,HasPlatinum,Difficulty,TimeToComplete,HasOnlineTrophies,Genre,Release(US),Guide" -Encoding UTF8

foreach($psNowGame in $psNowGames)
{
    Write-Host "$($psNowGame.Name)..."

    # No trophies
    if($psNowGame.Platform -eq "PS3(no_trophies)")
    {
        $psNowGame.HasGuide = $psNowGame.HasPlatinum = $psNowGame.Genre = $psNowGame.Release = $psNowGame.Guide = "n/a"
        $psNowGame.Difficulty = $psNowGame.HasOnlineTrophies = $psNowGame.TimeToComplete = "n/a"
        Add-GameInfoToFile $psNowGame $outputFile
        continue
    }

    $fileNameStartIndex = $psNowGame.Guide.IndexOf("/game/") + 6
    $fileNameEndIndex = $psNowGame.Guide.IndexOf("/guide/")
    $fileName = $psNowGame.Guide.Substring($fileNameStartIndex, $fileNameEndIndex - $fileNameStartIndex);
    $filePath = "$($cacheFolderName)\$($psNowGame.Platform)\$($fileName).html"

    if(-not (Test-Path $filePath -PathType Leaf))
    {
        Write-Error "Cannot find file: $filePath"
        return -1
    }

    $html = Get-Content -Path $filePath
    $xml = ConvertFrom-Html -Path $filePath

    # HasGuide
    $guideText = $xml.SelectNodes("//div[contains(@class, 'text-article__copy')]").InnerText
    $psNowGame.HasGuide = [bool]($guideText -ne '')

    # HasPlatinum
    $platinumLink = $xml.SelectNodes("//img[contains(@src, '/images/icons/trophy_platinum.png')]")
    $psNowGame.HasPlatinum = [bool]($platinumLink -ne $null)

    # Genre
    $genre = $xml.SelectNodes("//a[starts-with(@href, '/browsegames/genre/')]").InnerText
    if(($genre -eq $null) -or ($genre.Trim() -eq ''))
    {
        $genre = "n/a"
    }
    $psNowGame.Genre = $genre.Trim()

    # Release
    $release = $xml.SelectSingleNode("//img[contains(@src, '/images/flags/usa.jpg')]").NextSibling.InnerText
    if($release -eq $null)
    {
        $psNowGame.Release = "n/a"
    }
    else
    {
        $date = [DateTime]::Parse($release, [CultureInfo]::CreateSpecificCulture("en-US"))
        $psNowGame.Release = $date.ToString("yyyy-MM-dd");
    }

    if($psNowGame.HasGuide -eq $false)
    {
        $psNowGame.Difficulty = $psNowGame.HasOnlineTrophies = $psNowGame.TimeToComplete = "n/a"
        Add-GameInfoToFile $psNowGame $outputFile
        continue
    }

    $innerText = $xml.InnerText.ToLower().Replace(" ", "")
    
    # HasOnlineTrophies
    if($innerText.Contains("online:0") -or $innerText.Contains("onlinetrophies:0") -or
       $innerText.Contains("onlinetrophies:none") -or $innerText.Contains("onlinetrophies:n/a") -or
       $innerText.Contains("onlinetrophies:&nbsp;n/a") -or $innerText.Contains("onlinetrophies:&nbsp;none") -or
       $innerText.Contains("onlinetrophies:&nbsp;0") -or $innerText.Contains("online(breakdown):0") -or
       $innerText.Contains("onlinetrophies:no") -or (-not $innerText.Contains("online")))
    {
        $psNowGame.HasOnlineTrophies = $false
    }
    else
    {
        $psNowGame.HasOnlineTrophies = $true
    }

    # Difficulty
    if(($innerText -match 'difficulty(rating)*[?:-]*(&nbsp;)*(&ndash;)*(communityvote:)*(?<difficulty>[0-9]+)'))
    {
        $psNowGame.Difficulty = $Matches.difficulty.Trim()
    }
    elseif(($innerText -match 'estimated(.*)difficulty:(.*)(?<difficulty>[1-9])/10(.*)\n') -or ($innerText -match 'estimated(.*)difficulty:(.*)(?<difficulty>[1-9])(.*)\n'))
    {
        $difficulty = $Matches.difficulty.Trim()
        if($difficulty -eq "1")
        {
            $psNowGame.Difficulty = "unknown"
        }
        else
        {
            $psNowGame.Difficulty = $Matches.difficulty.Trim()
        }
    }
    else
    {
        $psNowGame.Difficulty = "unknown"
    }

    # TimeToComplete
    if($innerText -match 'platinum:([0-9]+)-(?<time>[0-9]+)')
    {
        $psNowGame.TimeToComplete = $Matches.time.Trim()
    }
    elseif(($innerText -match '(?<time>[0-9]+)\+hours') -or ($innerText -match '(?<time>[0-9]+)hours') -or
          ($innerText -match '(?<time>[0-9]+)\+hrs') -or ($innerText -match '(?<time>[0-9]+)hrs') -or
          ($innerText -match '(?<time>[0-9]+)hr') -or ($innerText -match '(?<time>[0-9]+)h'))
    {
        $psNowGame.TimeToComplete = $Matches.time.Trim()
    }
    elseif(($innerText -match '(?<time>[0-9]+)min'))
    {
        $psNowGame.TimeToComplete = 1
    }
    else
    {
        $psNowGame.TimeToComplete = "unknown"
    }

    # manual resolution of incorrectly parsed data
    if($manualResolution.ContainsKey($psNowGame.Name))
    {
        $value = $manualResolution[$psNowGame.Name]
        $psNowGame.Difficulty = $value.Difficulty
        $psNowGame.TimeToComplete = $value.TimeToComplete
        $psNowGame.HasOnlineTrophies = $value.HasOnlineTrophies
    }

    Add-GameInfoToFile $psNowGame $outputFile
}

Pop-Location
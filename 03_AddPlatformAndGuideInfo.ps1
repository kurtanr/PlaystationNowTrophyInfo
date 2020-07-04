# adds platform and guide info to list of PS NOW Games

Function Get-CleanGameName($gameName, $platformReplacement)
{
    $gameName = $gameName.Replace(":", "")
    $gameName = $gameName.Replace(".", "")
    $gameName = $gameName.Replace("!", "")
    $gameName = $gameName.Replace("- ", "")
    $gameName = $gameName.Replace("– ", "")
    $gameName = $gameName.Replace("+", "")
    $gameName = $gameName.Replace("’", "")
    $gameName = $gameName.Replace("'", "")
    $gameName = $gameName.Replace("™", "")
    $gameName = $gameName.Replace("&amp;", "&")
    $gameName = $gameName.Replace("(NA)", "")
    $gameName = $gameName.Replace("(Digital)", "")
    $gameName = $gameName.Replace("(NA & EU)", "")
    $gameName = $gameName.Replace("(NA & JP)", "")
    if($platformReplacement -eq "ps3")
    {
        $gameName = $gameName.Replace("(PS3)", "")
        $gameName = $gameName.Replace("(PS3 & Vita)", "")
        $gameName = $gameName.Replace("(PS3 & PS4)", "")
        $gameName = $gameName.Replace("(PS3, PS4 & Vita)", "")
    }
    elseif($platformReplacement -eq "ps4")
    {
        $gameName = $gameName.Replace("(PS4)", "")
        $gameName = $gameName.Replace("(PS4 & Vita)", "")
        $gameName = $gameName.Replace("(PS3 & PS4)", "")
        $gameName = $gameName.Replace("(PS4 & PS3)", "")
        $gameName = $gameName.Replace("(PS3, PS4 & Vita)", "")
        $gameName = $gameName.Replace("(PS4, PS3 & Vita)", "")
        $gameName = $gameName.Replace("(PS4, PS3, Vita)", "")
    }
    elseif($platformReplacement -eq "psn")
    {
        $gameName = $gameName.Replace("(PS3)", "")
        $gameName = $gameName.Replace("(PS4)", "")
        $gameName = $gameName.Replace("(PS3 & Vita)", "")
        $gameName = $gameName.Replace("(PS4 & Vita)", "")
        $gameName = $gameName.Replace("(PS3 & PS4)", "")
        $gameName = $gameName.Replace("(PS3, PS4 & Vita)", "")
        $gameName = $gameName.Replace("(PS4, PS3 & Vita)", "")
    }
    $gameName = $gameName.Replace(" ", "")
    $gameName = $gameName.Replace("1", "I")
    $gameName = $gameName.Replace("2", "II")
    $gameName = $gameName.Replace("3", "III")
    $gameName = $gameName.Replace("4", "IV")
    $gameName = $gameName.Trim()
    $gameName = $gameName.ToLower()
    return $gameName
}

Function Check-FileExists($filePath)
{
    if(-not (Test-Path $filePath))
    {
        throw "Cannot find file: $filePath"
    } 
}

Function Get-IsPs4Game([String] $gameName)
{
    foreach($psnGameWithTrophyGuideUrl in $psnGamesWithTrophyGuideUrl)
    {
        if($psnGameWithTrophyGuideUrl.Contains("PS4"))
        {
            $cleanGameName = Get-CleanGameName -gameName $psnGameWithTrophyGuideUrl.Substring(0,$psnGameWithTrophyGuideUrl.IndexOf("|")) -platformReplacement "psn"
            if($cleanGameName -eq $gameName)
            {
                return $true
            }
        }
    }

    return $false
}

Push-Location $PSScriptRoot

# TODO: add comments describing what files mean
$outputFile = ".\tmp\ps-now-games_en-us+.txt"
$inNameConversion = ".\customize\name-conversion.txt"
$inNotAvailableForPs4 = ".\customize\not-available-for-ps4.txt"
$inGamesWithNoTrophies = ".\customize\gamesWithNoTrophies.txt"
$inPsNow = ".\tmp\ps-now-games_en-us.txt"
$inPs3 = ".\tmp\ps3-games.txt"
$inPs4 = ".\tmp\ps4-games.txt"
$inPsn = ".\tmp\psn-games.txt"

if(Test-Path $outputFile)
{
    Remove-Item -Path $outputFile
}

Check-FileExists $inNameConversion
Check-FileExists $inNotAvailableForPs4
Check-FileExists $inGamesWithNoTrophies
Check-FileExists $inPsNow
Check-FileExists $inPs3
Check-FileExists $inPs4
Check-FileExists $inPsn

# name conversion
$nameConversionFileContent = Get-Content $inNameConversion
$nameConversionDict = @{}

Write-Host "Preparing name conversion..."
foreach($nameConversionEntry in $nameConversionFileContent)
{
    $originalName = $nameConversionEntry.Substring(0, $nameConversionEntry.IndexOf("|")).Trim()
    $convertedName = $nameConversionEntry.Substring($nameConversionEntry.IndexOf("|") + 1).Trim()
    $nameConversionDict.Add($originalName, $convertedName)
}

# games not available for PS4
$gamesNotAvailableForPs4FileContent = Get-Content $inNotAvailableForPs4
$gamesNotAvailableForPs4 = @()

Write-Host "Preparing list of games released on PS4 but available only as PS3 games..."
foreach($gamesNotAvailableForPs4Entry in $gamesNotAvailableForPs4FileContent)
{
    $gamesNotAvailableForPs4 += Get-CleanGameName -gameName $gamesNotAvailableForPs4Entry -platformReplacement "ps3"
}

# games with no trophy support
$gamesWithNoTrophiesFileContent = Get-Content $inGamesWithNoTrophies
$gamesWithNoTrophies = @()

Write-Host "Preparing list of games with no trophy support..."
foreach($gamesWithNoTrophiesEntry in $gamesWithNoTrophiesFileContent)
{
    $gamesWithNoTrophies += Get-CleanGameName -gameName $gamesWithNoTrophiesEntry -platformReplacement "ps3"
}

# PS3
$ps3GamesWithTrophyGuideUrl = Get-Content $inPs3
$ps3Games = @{}
$ps3GamesCount = 0

Write-Host "Preparing PS3 game list..."
foreach($ps3GameWithTrophyGuideUrl in $ps3GamesWithTrophyGuideUrl)
{
    $cleanGameName = Get-CleanGameName -gameName $ps3GameWithTrophyGuideUrl.Substring(0,$ps3GameWithTrophyGuideUrl.IndexOf("|")) -platformReplacement "ps3"
    $gameUrl = $ps3GameWithTrophyGuideUrl.Substring($ps3GameWithTrophyGuideUrl.IndexOf("|") + 2)
    $ps3Games.Add($cleanGameName, $gameUrl)
}

# PS4
$ps4GamesWithTrophyGuideUrl = Get-Content $inPs4
$ps4Games = @{}
$ps4GamesCount = 0

Write-Host "Preparing PS4 game list..."
foreach($ps4GameWithTrophyGuideUrl in $ps4GamesWithTrophyGuideUrl)
{
    $cleanGameName = Get-CleanGameName -gameName $ps4GameWithTrophyGuideUrl.Substring(0,$ps4GameWithTrophyGuideUrl.IndexOf("|")) -platformReplacement "ps4"
    $gameUrl = $ps4GameWithTrophyGuideUrl.Substring($ps4GameWithTrophyGuideUrl.IndexOf("|") + 2)
    $ps4Games.Add($cleanGameName, $gameUrl)
}

# PSN
$psnGamesWithTrophyGuideUrl = Get-Content $inPsn
$psnGames = @{}

Write-Host "Preparing PSN game list..."
foreach($psnGameWithTrophyGuideUrl in $psnGamesWithTrophyGuideUrl)
{
    $cleanGameName = Get-CleanGameName -gameName $psnGameWithTrophyGuideUrl.Substring(0,$psnGameWithTrophyGuideUrl.IndexOf("|")) -platformReplacement "psn"
    $gameUrl = $psnGameWithTrophyGuideUrl.Substring($psnGameWithTrophyGuideUrl.IndexOf("|") + 2)
    $psnGames.Add($cleanGameName, $gameUrl)
}

# PSNOW
$psNowGames = Get-Content $inPsNow
$numberOfPsNowGames = $psNowGames.Count
$numberOfPsNowGamesWithNoTrophySupport = 0

foreach($psnowGame in $psNowGames)
{
    if($nameConversionDict.ContainsKey($psnowGame))
    {
        $psnowGame = $nameConversionDict[$psnowGame]
    }

    $psnowGameClean = Get-CleanGameName -gameName $psNowGame

    Write-Host "$psnowGame ..."

    if($ps4Games.ContainsKey($psnowGameClean) -and (-not ($gamesNotAvailableForPs4.Contains($psnowGameClean))))
    {
        $trophyGuideUrl = $ps4Games[$psnowGameClean]
        $output = "$psnowGame,PS4,$trophyGuideUrl"
        $ps4GamesCount++
    }
    elseif($ps3Games.ContainsKey($psnowGameClean))
    {
        $trophyGuideUrl = $ps3Games[$psnowGameClean]
        $output = "$psnowGame,PS3,$trophyGuideUrl"
        $ps3GamesCount++
    }
    elseif($psnGames.ContainsKey($psnowGameClean))
    {
        $trophyGuideUrl = $psnGames[$psnowGameClean]

        if((Get-IsPs4Game -gameName $psnowGameClean) -and (-not ($gamesNotAvailableForPs4.Contains($psnowGameClean))))
        {
            $output = "$psnowGame,PS4(PSN),$trophyGuideUrl"
            $ps4GamesCount++
        }
        else
        {
            $output = "$psnowGame,PS3(PSN),$trophyGuideUrl"
            $ps3GamesCount++
        }
       
    }
    else
    {
        if ($gamesWithNoTrophies.Contains($psnowGameClean))
        {
            $output = "$psnowGame,PS3(no_trophies)"
            $numberOfPsNowGamesWithNoTrophySupport++
        }
        else
        {
            $output = "$psnowGame,-"
            Write-Host "Cannot determine platform" -ForegroundColor Red
        }
    }

    Add-Content -Path $outputFile -Value $output
}

$count = $ps3GamesCount + $ps4GamesCount + $numberOfPsNowGamesWithNoTrophySupport
$leftToResolve = $numberOfPsNowGames - $count

$summaryFile = ".\tmp\gameCount.txt"

$message = "PS3 games: $ps3GamesCount (+$numberOfPsNowGamesWithNoTrophySupport with no trophy support)"
Write-Host $message -ForegroundColor Green
Set-Content -Path $summaryFile -Value $message

$message = "PS4 games: $ps4GamesCount"
Write-Host $message -ForegroundColor Green
Add-Content -Path $summaryFile -Value $message

$message = "Determined platform for $count / $numberOfPsNowGames games ($leftToResolve left)"
Write-Host $message -ForegroundColor Green
Add-Content -Path $summaryFile -Value $message

Pop-Location
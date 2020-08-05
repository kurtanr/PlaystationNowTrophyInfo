# download guides

param (
    [ValidateSet('ps3', 'ps3(psn)', 'ps4', 'ps4(psn)')]
    [string]$platform="ps4"
)

class GameInfo
{
    [String]$Name
    [String]$Platform
    [String]$Guide
}

Function Check-FileExists($filePath)
{
    if(-not (Test-Path $filePath))
    {
        throw "Cannot find file: $filePath"
    } 
}

Function Download-Guide($url, $fileName)
{
try
{
    Write-Host "Retrieving content from: $url ..." -ForegroundColor Yellow

    $response = Invoke-WebRequest -URI $url -ErrorAction Stop
    $StatusCode = $response.StatusCode
}
catch
{
    Write-Error "Failed to retrieve content from: $url"
    Write-Error $_.Exception
    return -1
}
if($StatusCode -eq "200")
{
    Set-Content -Path $fileName -Value $response.Content
    Write-Host "Successfully saved guide" -ForegroundColor Green
}
else
{
    Write-Error -Value "Failed to retrieve content from: $url"
    Write-Error "Received status: $StatusCode"
    return -1
}
}

Push-Location $PSScriptRoot

$cacheFolderName = "cache"
$inPsNow = ".\tmp\ps-now-games_en-us+.txt"

if(-not (Test-Path $cacheFolderName -PathType Container))
{
    New-Item -ItemType Directory -Path $cacheFolderName -f
}

if(-not (Test-Path "$($cacheFolderName)\$($platform)" -PathType Container))
{
    New-Item -ItemType Directory -Path "$($cacheFolderName)\$($platform)" -f
}

Check-FileExists $inPsNow

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

Write-Host "Downloading guides..."
foreach($psNowGame in $psNowGames)
{
    if($psNowGame.Platform -ne $platform)
    {
        continue
    }

    Write-Host "$($psNowGame.Name)..."

    $fileNameStartIndex = $psNowGame.Guide.IndexOf("/game/") + 6
    $fileNameEndIndex = $psNowGame.Guide.IndexOf("/guide/")
    $fileName = $psNowGame.Guide.Substring($fileNameStartIndex, $fileNameEndIndex - $fileNameStartIndex);
    $filePath = "$($cacheFolderName)\$($platform)\$($fileName).html"

    if(Test-Path $filePath -PathType Leaf)
    {
        Write-Host "Already downloaded"
    }
    else
    {
        Download-Guide -url $psNowGame.Guide -fileName $filePath
    }
}

Pop-Location
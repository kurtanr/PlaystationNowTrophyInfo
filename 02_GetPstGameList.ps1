# retrieves list of all released games from playstationtrophies.org

param (
    [ValidateSet('ps3', 'psn', 'ps4')]
    [string]$platform="ps3"
)

$platformPst = ""
$pageCount = 1

if($platform.Equals("ps3"))
{
    $platformPst = "retail"
    $pageCount = 22
}
elseif($platform.Equals("psn"))
{
    $platformPst = "psn"
    $pageCount = 16
}
elseif($platform.Equals("ps4"))
{
    $platformPst = "ps4"
    $pageCount = 99
}
else
{
    Write-Error "Unknown platform: $platform"
    return -1
}

Function Get-GameInfo($url)
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
    Write-Host "Successfully retrieved content" -ForegroundColor Green
    Write-Host "Parsing content..." -ForegroundColor Yellow

    $html = ConvertFrom-Html -Content $response.RawContent
    $gameLinks = $html.SelectNodes("//div[contains(@class, 'divtext')]/table//a[contains(@class, 'linkT') and starts-with(@href, '/game/')]/..").InnerHtml
    foreach ($gameLink in $gameLinks)
    {
        $gameName = ""
        $gameUrl = ""

        $gameLink -match 'game/(?<gameUrl>.+)/trophies/' | Out-Null
        $gameUrl = $Matches.gameUrl
        
        $gameLink -match '<strong>(?<gameName>.+)</strong>' | Out-Null
        $gameName = $Matches.gameName

        if($gameName.StartsWith("Toukiden 2"))
        {
            # Remove Japanese characters from game title
            $gameName = "Toukiden 2"
        }
        elseif($gameName.Equals("The Swapper"))
        {
            # Game available for PS4
            $gameName = "The Swapper (PS3, PS4 & Vita)"
        }
        elseif($gameName.Equals("Lone Survivor: The Director's Cut (PS3 & Vita)"))
        {
            # Game available for PS4
            $gameName = "Lone Survivor: The Director's Cut (PS3, PS4 & Vita)"
        }
        elseif($platform.Equals("ps3") -and $gameName.Equals("Pro Evolution Soccer 2017 (PS3) (NA)"))
        {
            # Duplicate ps3 games
            continue
        }
        elseif($platform.Equals("ps4") -and
               ($gameName.Equals("Blue Rider (NA)") -or
               $gameName.Equals("Doodle Devil (PS4) (NA)") -or
               $gameName.Equals("Doodle God (PS4) (NA)") -or
               $gameName.Equals("Elliot Quest") -or
               $gameName.Equals("Giana Sisters: Twisted Dreams - Directors Cut") -or
               $gameName.Equals("Jotun: Valhalla Edition (NA)") -or
               $gameName.Equals("MasterCube (NA)") -or
               $gameName.Equals("Pneuma: Breath of Life") -or
               $gameName.Equals("Pro Evolution Soccer 2017 (PS4) (NA)") -or
               $gameName.Equals("SkyScrappers") -or
               $gameName.Equals("Toren (NA)") -or
               $gameName.Equals("Unepic (PS4)") -or
               $gameName.Equals("StarryNights -Helix-") -or
               $gameName.Equals("Wander (NA)")))
        {
            # Duplicate ps4 games
            continue
        }
        elseif($platform.Equals("psn") -and
               ($gameName.Equals("Doodle Devil (PS3) (NA)") -or
               $gameName.Equals("Doodle God (PS3) (NA)") -or
               $gameName.Equals("Q*Bert Rebooted (PS3) (NA)") -or
               $gameName.Equals("Valiant Hearts: The Great War (PS3) (JP)")))
        {
            # Duplicate psn games
            continue
        }

        $paddedGameName = $gameName.PadRight(50, " ")
        $gameInfo = "$paddedGameName | https://www.playstationtrophies.org/game/$gameUrl/guide/"
        Add-Content -Path $outputFile -Value $gameInfo -Encoding UTF8
    }

    Write-Host "Successfully parsed content, data saved to $outputFile" -ForegroundColor Green
}
else
{
    Write-Error -Value "Failed to retrieve content from: $url"
    Write-Error "Received status: $StatusCode"
    return -1
}
}

Function Add-AdditionalGame($gameName, $gameUrl)
{
    $paddedGameName = $gameName.PadRight(50, " ")
    $gameInfo = "$paddedGameName | https://www.playstationtrophies.org/game/$gameUrl/guide/"
    Add-Content -Path $outputFile -Value $gameInfo -Encoding UTF8
}

Push-Location $PSScriptRoot

$urlBase = "https://www.playstationtrophies.org/games/$platformPst"
$outputFile = ".\tmp\$platform-games.txt"

if(Test-Path $outputFile)
{
    Remove-Item -Path $outputFile
}

for (($i = 1); $i -le $pageCount; $i++)
{
    $url = "$urlBase/$i/"
    Get-GameInfo -url $url
}

# PS3 / PS4 games which are on Japanese / Vita lists
if($platform -eq "ps3")
{
    $gameName = "Battle of Tiles Ex"
    $gameUrl = "battle-of-tiles-ex"
    Add-AdditionalGame $gameName $gameUrl

    $gameName = "BlazBlue: Chrono Phantasma"
    $gameUrl = "blazblue-chronophantasma"
    Add-AdditionalGame $gameName $gameUrl

    $gameName = "Velocity Ultra"
    $gameUrl = "velocity-ultra-vita"
    Add-AdditionalGame $gameName $gameUrl
}
if($platform -eq "ps4")
{
    # only first 99 pages of PS4 games are accessible
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/t/9"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/t/10"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/t/11"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/t/12"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/u/1"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/u/2"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/v/1"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/v/2"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/w/1"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/w/2"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/w/3"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/w/4"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/x/"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/y/"
    Get-GameInfo -url "https://www.playstationtrophies.org/browsegames/ps4/z/"

    $gameName = "Mitsurugi Kamui Hikae"
    $gameUrl = "mitsurugi-kamui-hikae"
    Add-AdditionalGame $gameName $gameUrl

    $gameName = "The Witch and the Hundred Knight: Revival Edition"
    $gameUrl = "the-witch-and-the-hundred-knight-ps4"
    Add-AdditionalGame $gameName $gameUrl
}

Pop-Location
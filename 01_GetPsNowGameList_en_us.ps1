# retrieves list of all currently available PS NOW Games (US)

Push-Location $PSScriptRoot

$url = "https://www.playstation.com/en-us/explore/playstation-now/games/#allgames"
$outputFile = ".\tmp\ps-now-games_en-us.txt"

if(Test-Path $outputFile)
{
    Remove-Item -Path $outputFile
}

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
    $allGames = $html.SelectNodes("//div[contains(@id, 'games-block-inner')]//li").InnerText.Trim()

    foreach($game in $allGames)
    {
        if($game.Equals("Metal Gear Solid HD Collection"))
        {
            Add-Content -Path $outputFile -Value "Metal Gear Solid: Peace Walker HD"
            Add-Content -Path $outputFile -Value "Metal Gear Solid 2: Sons of Liberty HD"
            Add-Content -Path $outputFile -Value "Metal Gear Solid 3: Snake Eater HD"
        }
        elseif($game.Equals("Sly Cooper Collection"))
        {
            Add-Content -Path $outputFile -Value "Sly Cooper and the Thievius Raccoonus HD"
            Add-Content -Path $outputFile -Value "Sly 2: Band of Thieves HD"
            Add-Content -Path $outputFile -Value "Sly 3: Honor Among Thieves HD"
        }
        elseif($game.Equals("Devil May Cry HD Collection"))
        {
            Add-Content -Path $outputFile -Value "Devil May Cry"
            Add-Content -Path $outputFile -Value "Devil May Cry 2"
            Add-Content -Path $outputFile -Value "Devil May Cry 3"
        }
        elseif($game.Equals("Silent Hill HD Collection"))
        {
            Add-Content -Path $outputFile -Value "Silent Hill 2 HD"
            Add-Content -Path $outputFile -Value "Silent Hill 3 HD"
        }
        elseif($game.Equals("Sam &amp; Max: Beyond Time and Space"))
        {
            Add-Content -Path $outputFile -Value "Sam & Max: Beyond Time and Space - Episode 1: Ice Station Santa"
            Add-Content -Path $outputFile -Value "Sam & Max: Beyond Time and Space - Episode 2: Moai Better Blues"
            Add-Content -Path $outputFile -Value "Sam & Max: Beyond Time and Space - Episode 3: Night of the Raving Dead"
            Add-Content -Path $outputFile -Value "Sam & Max: Beyond Time and Space - Episode 4:  Chariots of the Dogs"
            Add-Content -Path $outputFile -Value "Sam & Max: Beyond Time and Space - Episode 5: What's New, Beelzebub?"
        }
        elseif($game.Equals("Sam &amp; Max The Devil's Playhouse"))
        {
            Add-Content -Path $outputFile -Value "Sam & Max: The Devil's Playhouse - Episode 1: The Penal Zone"
            Add-Content -Path $outputFile -Value "Sam & Max: The Devil's Playhouse - Episode 2: The Tomb of Sammun-Mak"
            Add-Content -Path $outputFile -Value "Sam & Max: The Devil's Playhouse - Episode 3: They Stole Max's Brain"
            Add-Content -Path $outputFile -Value "Sam & Max: The Devil's Playhouse - Episode 4: Beyond the Alley of the Dolls"
            Add-Content -Path $outputFile -Value "Sam & Max: The Devil's Playhouse - Episode 5: The City That Dares Not Sleep"
        }
        elseif($game.Equals("Strong Bad's Cool Game for Attractive People"))
        {
            Add-Content -Path $outputFile -Value "Strong Bad's Cool Game for Attractive People - Episode 1: Homestar Ruiner"
            Add-Content -Path $outputFile -Value "Strong Bad's Cool Game for Attractive People - Episode 2: Strong Badia the Free"
            Add-Content -Path $outputFile -Value "Strong Bad's Cool Game for Attractive People - Episode 3: Baddest of the Bands"
            Add-Content -Path $outputFile -Value "Strong Bad's Cool Game for Attractive People - Episode 4: Dangeresque 3: The Criminal Projective"
            Add-Content -Path $outputFile -Value "Strong Bad's Cool Game for Attractive People - Episode 5: 8-Bit is Enough"
        }
        elseif($game.Equals("Borderlands: Game of the Year Edition"))
        {
            Add-Content -Path $outputFile -Value "Borderlands: The Pre-Sequel: The Handsome Collection"
            Add-Content -Path $outputFile -Value "Borderlands 2: The Handsome Collection"
        }
        elseif($game.Equals("The Last of Us: Left Behind") -or 
               $game.Equals("Red Dead Redemption: Undead Nightmare") -or 
               $game.Equals("PixelJunk Monsters Encore") -or 
               $game.Equals("Guilty Gear Xrd Rev 2"))
        {
            # trophies are added to the main game
        }
        elseif($game.Equals("Bloodborne™") -or 
               $game.Equals("CARS MATER-NATIONAL"))
        {
            # already on the list under different name
        }
        else 
        {
            Add-Content -Path $outputFile -Value $game
        }
    }

    Write-Host "Successfully parsed content, data saved to $outputFile" -ForegroundColor Green
}
else
{
    Write-Error -Value "Failed to retrieve content from: $url"
    Write-Error "Received status: $StatusCode"
    return -1
}

Pop-Location
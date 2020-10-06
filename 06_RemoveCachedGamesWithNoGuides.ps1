# remove cached games with no guides

Push-Location $PSScriptRoot\cache

$filePaths = Get-ChildItem -Recurse -File | select FullName
$counter = 0

foreach($filePath in $filePaths)
{
    $xml = ConvertFrom-Html -Path $filePath.FullName
    $guideLink = $xml.SelectNodes("//img[contains(@src, '/images/site/questionmark.gif')]")
    if($guideLink -eq $null)
    {
        $fileName = Split-Path $filePath.FullName -Leaf
        Write-Host $fileName
        Remove-Item -Path $filePath.FullName
        $counter++
    }
}
Write-Host "Removed $counter files"

Pop-Location

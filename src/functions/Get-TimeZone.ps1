<#
.SYNOPSIS
    Returns TimeZone information for geographic coordinates (Latitide and Longitude).
.DESCRIPTION
    This cmdlet utilizes Requesting the time zone information for a specific Latitude/Longitude pair and  will return the name of that time zone, ID and Local time of the place.

    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleTimezone_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/timezone/get-api-key
.PARAMETER Coordinates
    The latitude and longitude values specifying the location for which you wish to obtain the Timezone information
.EXAMPLE
    PS D:\> Get-TimeZone -Coordinates "38.8976763,-77.0365298"

    TimeZone              TimeZoneID       LocalTime           
    --------              ----------       ---------           
    Eastern Daylight Time America/New_York 5/13/2016 5:14:42 PM
    
    
    
    PS D:\> "white house","Microsoft redmund" | Get-GeoCoding | Select-Object Coordinates -ExpandProperty Coordinates | Get-TimeZone
    
    TimeZone              TimeZoneID          LocalTime           
    --------              ----------          ---------           
    Eastern Daylight Time America/New_York    5/13/2016 5:15:14 PM
    Pacific Daylight Time America/Los_Angeles 5/13/2016 2:15:14 PM
        
    In above example, Function returns Timezone information like TimeZone Name and Local time for the geographical cordinates (Latitude and Longitude).
    You can also pass multiple latitude and longitude values through pipeline to the cmdlet, to get the corresponding Timezones\Local Times.
.EXAMPLES
    PS D:\> "new delhi","white house","microsoft redmund"| gtz

    TimeZone              TimeZoneID       LocalTime            DSTOffsetHours
    --------              ----------       ---------            --------------
    India Standard Time   Asia/Calcutta    5/25/2016 3:32:25 PM 00:00:00      
    Eastern Daylight Time America/New_York 5/25/2016 6:02:25 AM 01:00:00      
    Pacific Daylight Time America/Los_A... 5/25/2016 3:02:25 AM 01:00:00      

    Like in the above example you can also pass the places instead of coordinates.

.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#>  
Function Get-TimeZone
{
    [cmdletbinding()]
    Param(
            [Parameter(ValueFromPipeline=$True, HelpMessage="Enter Latitude and Longitude")] [String[]] $Coordinates,
            [Parameter(ValueFromPipeline=$True, HelpMessage="Enter Name of the place")] [String[]] $Place
    )

    Begin
    {
        If(!$env:GoogleTimezone_API_Key)
        {
            Throw "You need to register and get an API key and save it as environment variable `$env:GoogleTimezone_API_Key = `"YOUR API KEY`" `nFollow this link and get the API Key - https://developers.google.com/maps/documentation/timezone/get-api-key `n`n "
        }

        $SourceDateTime =  Get-Date "January 1, 1970"
        $CurrentDateTime = Get-Date
        $TimeStamp = [int]($CurrentDateTime - $SourceDateTime).totalseconds

    }
    Process
    {

        If($Place)
        {
            $Coordinates = $Place | ForEach-Object {(Get-GeoCoding -Address $_)[0].coordinates}
        }

        ForEach($Item in $Coordinates)
        {
            Try
            {
                $Webpage = Invoke-WebRequest -Uri "https://maps.googleapis.com/maps/api/timezone/json?location=$Item&timestamp=$TimeStamp&key=$env:GoogleTimezone_API_Key" -UseBasicParsing -ErrorVariable EV                           
                $Webpage.Content | ConvertFrom-Json|`
                Select-Object-Object @{n='TimeZone';e={$_.timezonename}}, @{n='TimeZoneID';e={$_.timezoneID}}, @{n='LocalTime';e={($SourceDateTime.ToUniversalTime()).AddSeconds($_.dstOffset+$_.rawoffset+$TimeStamp)}}, @{n='DSTOffsetHours';e={([timespan]::FromSeconds($_.dstoffset)).tostring("hh\:mm\:ss")}}
            }
            Catch
            {
                "Something went wrong, please try running again."
                $ev.message              
            }
        }
    }
}#end function Get-TimeZone
Set-Alias -Name gtz -Value Get-TimeZone
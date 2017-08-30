<#
.SYNOPSIS
    This Cmdlet returns location based on information using nearby WiFi access points.
.DESCRIPTION
    The Cmdlet captures information of nearby WiFi nodes and send it to Google Maps Geolocation API to return location and Geographical coordinates.

    NOTE : Incase there are no Wireless acceses point (WiFi) available, API won't be able to return the location information.
    
    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleGeoloc_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/geolocation/get-api-key

.PARAMETER WithCoordinates
    To return the geographical coordinates with the human readable address.
.EXAMPLE
    PS D:\> WhereAmI
    U-15 Road, U Block, DLF Phase 3, Sector 24, Gurgaon, Haryana 122010, India

    Run the cmdlet and it will return your Location address using your Wifi Nodes.
.EXAMPLE
    PS D:\> WhereAmI -WithCoordinates | fl
    
    Address     : U-15 Road, U Block, DLF Phase 3, Sector 24, Gurgaon, Haryana 122010, India
    Coordinates : 28.494853,77.095529

    Use '-WithCoordinates' switch to return the geographical coordinates with the address.
.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#> 
Function Get-GeoLocation
{
    Param(
            [Switch] $WithCoordinates
    )
    
    $WiFiAccessPointMACAdddress = netsh wlan show networks mode=Bssid | Where-Object {$_ -like "*BSSID*"} | ForEach-Object {($_.split(" ")[-1]).toupper()}
    
    If(!$env:GoogleGeoloc_API_Key)
    {
        Throw "You need to register and get an API key and save it as environment variable `$env:GoogleGeoloc_API_Key = `"YOUR API KEY`" `nFollow this link and get the API Key - https://developers.google.com/maps/documentation/geolocation/get-api-key `n`n "
    }

    If(!$WiFiAccessPointMACAdddress)
    {
        "No Wifi Access point found! Please make sure your WiFi is ON."
    }
    Else
    {

        $body = @{wifiAccessPoints = @{macAddress = $($WiFiAccessPointMACAdddress[0])},@{macAddress = $($WiFiAccessPointMACAdddress[1])}}|ConvertTo-Json

        Try
        {
            $webpage = Invoke-WebRequest -Uri "https://www.googleapis.com/geolocation/v1/geolocate?key=$env:GoogleGeoloc_API_Key" `
                                         -ContentType "application/json" `
                                         -Body $Body `
                                         -UseBasicParsing `
                                         -Method Post `
                                         -ErrorVariable EV
        }
        Catch
        {
            "Something went wrong, please try running again."
            $ev.message 
        }
  
        $YourCoordinates = ($webpage.Content | ConvertFrom-Json).location

        #Converting your corridnates to "Latitude,Longitude" string in order to reverse geocode it to obtain your address
        $LatLang = ($YourCoordinates | Select-Object @{n='LatLng';e={"$("{0:N7}" -f $_.lat),$("{0:N7}" -f $_.lng)"}}).LatLng 
        
        #Your address
        $Address = ($LatLang| Get-ReverseGeoCoding).Address

        If($WithCoordinates)
        {
            ''|Select-Object @{n='Address';e={$Address}}, @{n='Coordinates';e={$LatLang}}
        }
        else
        {
            $Address
        }
    }
}#end function Get-GeoLocation
Set-Alias -Name WhereAmI -Value Get-GeoLocation
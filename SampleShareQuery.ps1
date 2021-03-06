$computername = Get-Content 'Z:\Documents\ShareServerNodes.txt'
# Will create csv at path - it complains it does not exists obviously YET, see near bottom page commented out for now
$CSVpath = "Z:\Documents\KnownShares.csv"

remove-item $CSVpath 

$Report = @() 

foreach ($computer in $computername) {
Write-host $computer 

# Mapped Drives
#$colDrives = Get-WmiObject Win32_MappedLogicalDisk -ComputerName $computer 
# Shares
$colDrives = Get-WmiObject Win32_Share -ComputerName $computer

foreach ($objDrive in $colDrives) { 
    # For each mapped drive - build a hash containing information
    #$hash = @{ 
    #    ComputerName       = $computer
    #    MappedLocation     = $objDrive.ProviderName 
    #    DriveLetter   = $objDrive.DeviceId 
    #}
     
    # For each Shares drive - build hash containing info
    $hash = @{ 
        ComputerName       = $computer
        path               = $objDrive.path
        name               = $objDrive.name
        description        = $objDrive.description
        #type               = $objDrive.type
                
    }
    
    # Add the hash to a new object
    $objDriveInfo = new-object PSObject -Property $hash
    # Store our new object within the report array
    $Report += $objDriveInfo
} 

# Export our report array to CSV and store as our dynamic file name
$Report | Export-Csv -NoType $CSVpath #$filenamestring
}

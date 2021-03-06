$computername = Get-Content 'Z:\Documents\ShareServerNodes.txt'
# Will create csv at path - it complains it does not exists obviously YET,
$CSVpath = "Z:\Documents\KnownSharesPermissions.csv"

remove-item $CSVpath 

$Report = @() 

foreach ($computer in $computername) {
 
    $shares = gwmi -Class win32_share -ComputerName $computer | select -ExpandProperty Name  
     
    foreach ($share in $shares) {  
        
        $acl = $null  
        Write-Host $share -ForegroundColor Green  
        Write-Host $('-' * $share.Length) -ForegroundColor Green  
        $objShareSec = Get-WMIObject -Class Win32_LogicalShareSecuritySetting -Filter "name='$Share'"  -ComputerName $computer 
        try {  
            $SD = $objShareSec.GetSecurityDescriptor().Descriptor    
            foreach($ace in $SD.DACL){   
                $UserName = $ace.Trustee.Name      
                If ($ace.Trustee.Domain -ne $Null) {$UserName = "$($ace.Trustee.Domain)\$UserName"}    
                If ($ace.Trustee.Name -eq $Null) {$UserName = $ace.Trustee.SIDString }                                              
                [Array]$ACL += New-Object Security.AccessControl.FileSystemAccessRule($UserName, $ace.AccessMask, $ace.AceType)                  
                
                # Kept original Array above, for now, but it is not strictly necessary
                $SAFObject = New-Object Security.AccessControl.FileSystemAccessRule($UserName, $ace.AccessMask, $ace.AceType)
                # For each PC build hash containing info 
                $hash = @{ 
                    ComputerName       = $computer
                    ShareName          = $Share
                    UserName           = $UserName
                    IdentityReference  = $SAFObject.IdentityReference
                    AccessControlType  = $SAFObject.AccessControlType
                    FileSystemRights   = $SAFObject.FileSystemRights
                    IsInherited        = $SAFObject.IsInherited
                    InheritanceFlags   = $SAFObject.InheritanceFlags
                    PropagationFlags   = $SAFObject.PropagationFlags                    
                }
                
                # Add the hash to a new object
                $objDriveInfo = new-object PSObject -Property $hash
                # Store our new object within the report array
                $Report += $objDriveInfo
                
            } #end foreach ACE            
        } # end try  
        catch  
            { Write-Host "Unable to obtain permissions for $share" }  
    # SHow what has been collected on the STDOUT (standard output i.e. screen/console
    $ACL  
    Write-Host $('=' * 50)    
    
    } # end foreach $share
        
# Export our report array to CSV and store as our dynamic file name
$Report | Export-Csv -NoType $CSVpath #$filenamestring 
}
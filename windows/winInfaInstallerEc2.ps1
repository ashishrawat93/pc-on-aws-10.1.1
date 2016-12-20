$env:USERNAME="Administrator"
$env:USERDOMAIN=$env:COMPUTERNAME
$env:JOIN_HOST_NAME="$env:COMPUTERNAME"
$env:DOMAIN_USER="Administrator"
$env:CLOUD_SUPPORT_ENABLE=1 

$domainpass=$args[0]
$dbpass = $args[1]
$repopass = $args[2]
$passKeyPhrase = $args[3]

C:\InfaEc2Scripts\generateTnsOra.ps1 $env:DB_SERVICENAME $env:DB_ADDRESS $env:DB_PORT 2>  C:\InfaServiceLog.log

$env:DB_ADDRESS=$env:DB_ADDRESS+":"+$env:DB_PORT
$USER_INSTALL_DIR="C:\Informatica\10.1.1"
$KEY_DEST_LOCATION="C:\Informatica\10.1.1\isp\config\keys"


$PROPERTYFILE="C:\infainstaller\SilentInput.properties"

(gc $PROPERTYFILE | %{$_ -replace '^CREATE_DOMAIN=.*$',"CREATE_DOMAIN=$env:CREATE_DOMAIN"  `
`
-replace '^JOIN_DOMAIN=.*$',"JOIN_DOMAIN=$env:JOIN_DOMAIN"  `
`
-replace '^CLOUD_SUPPORT_ENABLE=.*$',"CLOUD_SUPPORT_ENABLE=$env:CLOUD_SUPPORT_ENABLE"  `
`
-replace '^ENABLE_USAGE_COLLECTION=.*$',"ENABLE_USAGE_COLLECTION=1"  `
`
-replace '^USER_INSTALL_DIR=.*$',"USER_INSTALL_DIR=$USER_INSTALL_DIR"  `
`
-replace '^KEY_DEST_LOCATION=.*$',"KEY_DEST_LOCATION=$KEY_DEST_LOCATION"  `
`
-replace '^PASS_PHRASE_PASSWD=.*$',"PASS_PHRASE_PASSWD=$passKeyPhrase"  `
`
-replace '^SERVES_AS_GATEWAY=.*$',"SERVES_AS_GATEWAY=$env:SERVES_AS_GATEWAY" `
`
-replace '^DB_TYPE=.*$',"DB_TYPE=$env:DB_TYPE" `
`
-replace '^DB_UNAME=.*$',"DB_UNAME=$env:DB_UNAME" `
`
-replace '^DB_SERVICENAME=.*$',"DB_SERVICENAME=$env:DB_SERVICENAME" `
`
-replace '^DB_ADDRESS=.*$',"DB_ADDRESS=$env:DB_ADDRESS" `
`
-replace '^DOMAIN_NAME=.*$',"DOMAIN_NAME=$env:DOMAIN_NAME" `
`
-replace '^NODE_NAME=.*$',"NODE_NAME=$env:NODE_NAME" `
`
-replace '^DOMAIN_PORT=.*$',"DOMAIN_PORT=6005" `
`
-replace '^JOIN_NODE_NAME=.*$',"JOIN_NODE_NAME=$env:JOIN_NODE_NAME" `
`
-replace '^JOIN_HOST_NAME=.*$',"JOIN_HOST_NAME=$env:JOIN_HOST_NAME" `
`
-replace '^JOIN_DOMAIN_PORT=.*$',"JOIN_DOMAIN_PORT=6005" `
`
-replace '^DOMAIN_USER=.*$',"DOMAIN_USER=$env:DOMAIN_USER" `
`
-replace '^DOMAIN_HOST_NAME=.*$',"DOMAIN_HOST_NAME=$env:DOMAIN_HOST_NAME" `
`
-replace '^DOMAIN_PSSWD=.*$',"DOMAIN_PSSWD=$domainpass" `
`
-replace '^DOMAIN_CNFRM_PSSWD=.*$',"DOMAIN_CNFRM_PSSWD=$domainpass" `
`
-replace '^DB_PASSWD=.*$',"DB_PASSWD=$dbpass" 

}) | sc $PROPERTYFILE
cd C:\infainstaller

C:\infainstaller\silentInstall.bat | Out-Null



function createPCServices() {
    #ENABLE CRS AND IS after the issue of db resolution through native clients is resolved
	
    ($out = C:\Informatica\10.1.1\isp\bin\infacmd createRepositoryService -dn $env:DOMAIN_NAME  -nn $env:NODE_NAME -sn $env:REPOSITORY_SERVICE_NAME -so DBUser=$env:REPO_USER DatabaseType=$env:DB_TYPE DBPassword=$repopass ConnectString=$env:DB_SERVICENAME CodePage="UTF-8 encoding of Unicode" OperatingMode=NORMAL -un $env:DOMAIN_USER -pd $domainpass -sd ) | Out-Null
    $code=$LASTEXITCODE
    ac C:\InfaServiceLog.log $out 
    if ($env:SINGLE_NODE -eq 1 ) {
        ($out = C:\Informatica\10.1.1\isp\bin\infacmd createintegrationservice -dn $env:DOMAIN_NAME -nn $env:NODE_NAME -un $env:DOMAIN_USER -pd $domainpass -sn $env:INTEGRATION_SERVICE_NAME -rs  $env:REPOSITORY_SERVICE_NAME -ru $env:DOMAIN_USER -rp $domainpass  -po codepage_id=106 -sd -ev INFA_CODEPAGENAME=UTF-8) | Out-Null
        $code=$code -bor $LASTEXITCODE
        ac C:\InfaServiceLog.log $out 
    } else {
       ($out = C:\Informatica\10.1.1\isp\bin\infacmd creategrid -dn $env:DOMAIN_NAME -un $env:DOMAIN_USER -pd $domainpass -gn $env:GRID_NAME -nl $env:NODE_NAME) | Out-Null        

       $code = $LASTEXITCODE

        ac C:\InfaServiceLog.log $out 

       ($out = C:\Informatica\10.1.1\isp\bin\infacmd createintegrationservice -dn $env:DOMAIN_NAME -gn $env:GRID_NAME -un $env:DOMAIN_USER -pd $domainpass -sn $env:INTEGRATION_SERVICE_NAME -rs  $env:REPOSITORY_SERVICE_NAME -ru $env:DOMAIN_USER -rp $domainpass  -po codepage_id=106 -sd -ev INFA_CODEPAGENAME=UTF-8) | Out-Null

        $code = $code -bor $LASTEXITCODE

        ac C:\InfaServiceLog.log $out 

        ($out = C:\Informatica\10.1.1\isp\bin\infacmd updateServiceProcess -dn $env:DOMAIN_NAME -un $env:DOMAIN_USER -pd $domainpass -sn $env:INTEGRATION_SERVICE_NAME -nn $env:NODE_NAME -po CodePage_Id=106) | Out-Null

        $code = $code -bor $LASTEXITCODE

        ac C:\InfaServiceLog.log $out 
    }
	if ($env:ADD_LICENSE_CONDITION -eq 1) {
		ac  C:\InfaServiceLog.log "Adding License" 
		
		($out = C:\Informatica\10.1.1\isp\bin\infacmd addlicense -dn $env:DOMAIN_NAME -un $env:DOMAIN_USER -pd $domainpass -ln license -lf C:\Informatica\10.1.1\License.key)
		
		$code=$code -bor $LASTEXITCODE
		
		rm  C:\Informatica\10.1.1\License.key
		ac C:\InfaServiceLog.log $out 
	}
     exit $code


}

if ($env:JOIN_DOMAIN -eq 0 ) {
        ac  C:\InfaServiceLog.log "creating pc services" 
        createPCServices
   
} else {
     ($out = C:\Informatica\10.1.1\isp\bin\infacmd updategrid -dn $env:DOMAIN_NAME -un $env:DOMAIN_USER -pd $domainpass -gn $env:GRID_NAME -nl  $env:JOIN_NODE_NAME -ul) |Out-Null
     $code = $LASTEXITCODE
     ac C:\InfaServiceLog.log $out
     ($out = C:\Informatica\10.1.1\isp\bin\infacmd updateServiceProcess -dn $env:DOMAIN_NAME -un $env:DOMAIN_USER -pd $domainpass -sn $env:INTEGRATION_SERVICE_NAME -nn $env:JOIN_NODE_NAME -po CodePage_Id=106 -ev INFA_CODEPAGENAME=UTF-8) | Out-Null
     $code = $code -bor $LASTEXITCODE
     ac C:\InfaServiceLog.log $out
     exit $code
}




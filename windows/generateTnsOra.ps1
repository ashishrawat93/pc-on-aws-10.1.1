$SERVICENAME=$args[0]
$HOSTNAME=$args[1]
$PORT=$args[2]


$ORAFILE=$env:TNS_ADMIN+"\tnsnames.ora"

(gc $ORAFILE | %{$_ -replace '<SERVICENAME>',"$SERVICENAME"  `
`
-replace '<HOSTNAME>',"$HOSTNAME"  `
`
-replace '<PORT>',"$PORT"  `

}) | sc $ORAFILE

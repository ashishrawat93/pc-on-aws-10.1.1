DOMAIN_PORT=6005
JOIN_DOMAIN_PORT=6005
DOMAIN_USER=$DOMAIN_USER_NAME
JOIN_HOST_NAME=$HOSTNAME

domainpass=$1
dbpass=$2
repopass=$3
passkey=$4

CLOUD_SUPPORT_ENABLE=1

USER_INSTALL_DIR="\/home\/ec2-user\/Informatica\/10.1.1"
KEY_DEST_LOCATION="\/home\/ec2-user\/Informatica\/10.1.1\/isp\/config\/keys"

function setENV {
    echo "Setting env"
    ORACLE_HOME=/home/oracle/product/11.2.0.4
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/oracle/product/11.2.0.4/lib
    TNS_ADMIN=$ORACLE_HOME/network/admin
    export ORACLE_HOME LD_LIBRARY_PATH TNS_ADMIN

}
setENV
sh /home/ec2-user/InfaEc2Scripts/generateTnsOra.sh $DB_SERVICENAME $DB_ADDRESS $DB_PORT &> /home/ec2-user/InfaServiceLog.log


DB_ADDRESS=$DB_ADDRESS":"$DB_PORT

sed -i s/^USER_INSTALL_DIR=.*/USER_INSTALL_DIR=$USER_INSTALL_DIR/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^KEY_DEST_LOCATION=.*/KEY_DEST_LOCATION=$KEY_DEST_LOCATION/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^CLOUD_SUPPORT_ENABLE=.*/CLOUD_SUPPORT_ENABLE=$CLOUD_SUPPORT_ENABLE/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^ENABLE_USAGE_COLLECTION=.*/ENABLE_USAGE_COLLECTION=1/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^CREATE_DOMAIN=.*/CREATE_DOMAIN=$CREATE_DOMAIN/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^PASS_PHRASE_PASSWD=.*/PASS_PHRASE_PASSWD=$4/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DOMAIN_USER=.*/DOMAIN_USER=$DOMAIN_USER/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^JOIN_DOMAIN=.*/JOIN_DOMAIN=$JOIN_DOMAIN/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^SERVES_AS_GATEWAY=.*/SERVES_AS_GATEWAY=$SERVES_AS_GATEWAY/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DB_TYPE=.*/DB_TYPE=$DB_TYPE/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DB_UNAME=.*/DB_UNAME=$DB_UNAME/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DB_PASSWD=.*/DB_PASSWD=$2/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DOMAIN_PSSWD=.*/DOMAIN_PSSWD=$1/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DOMAIN_CNFRM_PSSWD=.*/DOMAIN_CNFRM_PSSWD=$1/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DB_SERVICENAME=.*/DB_SERVICENAME=$DB_SERVICENAME/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DB_ADDRESS=.*/DB_ADDRESS=$DB_ADDRESS/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DOMAIN_NAME=.*/DOMAIN_NAME=$DOMAIN_NAME/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^NODE_NAME=.*/NODE_NAME=$NODE_NAME/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DOMAIN_PORT=.*/DOMAIN_PORT=$DOMAIN_PORT/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^JOIN_NODE_NAME=.*/JOIN_NODE_NAME=$JOIN_NODE_NAME/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^JOIN_HOST_NAME=.*/JOIN_HOST_NAME=$JOIN_HOST_NAME/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^JOIN_DOMAIN_PORT=.*/JOIN_DOMAIN_PORT=$JOIN_DOMAIN_PORT/ /home/ec2-user/infainstaller/SilentInput.properties

sed -i s/^DOMAIN_HOST_NAME=.*/DOMAIN_HOST_NAME=$DOMAIN_HOST_NAME/ /home/ec2-user/infainstaller/SilentInput.properties

setENV
cd /home/ec2-user/infainstaller
echo Y Y | sh silentinstall.sh 

USER_INSTALL_DIR="/home/ec2-user/Informatica/10.1.1"
chown -R ec2-user.ec2-user $USER_INSTALL_DIR


function createPCServices {
     echo "creating PC services" >> /home/ec2-user/InfaServiceLog.log

    sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh  createrepositoryservice -dn $DOMAIN_NAME -nn $NODE_NAME -sn $REPOSITORY_SERVICE_NAME -so DBUser=$REPO_USER DatabaseType=$DB_TYPE DBPassword=$dbpass ConnectString=$DB_SERVICENAME CodePage="UTF-8 encoding of Unicode"  OperatingMode=NORMAL -un $DOMAIN_USER -pd $domainpass -sd &>> /home/ec2-user/InfaServiceLog.log

       EXITCODE=$?

       if [ $SINGLE_NODE -eq 1 ]
	then
	   sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh  createintegrationservice -dn $DOMAIN_NAME -nn $NODE_NAME -un $DOMAIN_USER -pd $domainpass -sn $INTEGRATION_SERVICE_NAME  -rs $REPOSITORY_SERVICE_NAME  -ru $DOMAIN_USER -rp $domainpass -po codepage_id=106 -sd -ev INFA_CODEPAGENAME=UTF-8 &>> /home/ec2-user/InfaServiceLog.log

	   	EXITCODE=$(($? | EXITCODE))
	else 
	  sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh  creategrid -dn $DOMAIN_NAME -un $DOMAIN_USER -pd $domainpass -gn $GRID_NAME -nl $NODE_NAME &>> /home/ec2-user/InfaServiceLog.log

	  	EXITCODE=$(($? | EXITCODE))

	  sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh  createintegrationservice -dn $DOMAIN_NAME -gn $GRID_NAME -un $DOMAIN_USER -pd $domainpass -sn $INTEGRATION_SERVICE_NAME -rs  $REPOSITORY_SERVICE_NAME -ru $DOMAIN_USER -rp $domainpass  -po codepage_id=106 -sd -ev INFA_CODEPAGENAME=UTF-8 &>> /home/ec2-user/InfaServiceLog.log

	  	EXITCODE=$(($? | EXITCODE))

	fi

        if [ $ADD_LICENSE_CONDITION -eq 1 ]
    then
        echo "Adding license" >>  /home/ec2-user/InfaServiceLog.log

        sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh addlicense -dn $DOMAIN_NAME -un $DOMAIN_USER -pd $domainpass -ln license -lf /home/ec2-user/Informatica/10.1.1/License.key &>> /home/ec2-user/InfaServiceLog.log
        
        EXITCODE=$(($? | EXITCODE))

        rm -f /home/ec2-user/Informatica/10.1.1/License.key
     fi   
         exit $EXITCODE

}
if [ $JOIN_DOMAIN -eq 0 ]
then
	createPCServices
else
     sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh  updategrid -dn $DOMAIN_NAME -un $DOMAIN_USER -pd $domainpass -gn $GRID_NAME -nl  $JOIN_NODE_NAME -ul &>> /home/ec2-user/InfaServiceLog.log

    EXITCODE=$?

     sh sleep 30;

     sh /home/ec2-user/Informatica/10.1.1/isp/bin/infacmd.sh  updateServiceProcess -dn $DOMAIN_NAME -un $DOMAIN_USER -pd $domainpass -sn $INTEGRATION_SERVICE_NAME -nn $JOIN_NODE_NAME -po CodePage_Id=106 -ev INFA_CODEPAGENAME=UTF-8 &>> /home/ec2-user/InfaServiceLog.log
    
     EXITCODE=$(($? | EXITCODE))
     
     exit $EXITCODE

fi





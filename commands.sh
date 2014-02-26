#!/bin/bash
# script till P2

# CLIENT

# UserIDs
person[0]='190002021110' 	#Patient
person[1]='199003032220' 	#Patient
person[2]='198004043330' 	#Patient
person[3]='197005054440' 	#Patient
person[4]='1101' 	#Nurse
person[5]='1201' 	#Nurse
person[6]='1202' 	#Nurse
person[7]='1110' 	#Dr
person[8]='1210' 	#Dr
person[9]='1700' 	#Gov

#Passwords: Clientkeystores
passwd[0]='abc123'
passwd[1]='123456'
passwd[2]='rockyou'
passwd[3]='fdjhfjkdhsfjk'
passwd[4]='password'
passwd[5]='password'
passwd[6]='password'
passwd[7]='password'
passwd[8]='password'
passwd[9]='password'

#Password: CA
CApass='passCAword'

#Password: Clienttruststore
CTSpass='CLIENTpassTRUSTwordSTORE'

#Password: key-pairs (Client)
#CKPpass='password123'
CKPpass[0]='1110'
CKPpass[1]='2220'
CKPpass[2]='3330'
CKPpass[3]='4440'
CKPpass[4]='1101'
CKPpass[5]='1201'
CKPpass[6]='1202'
CKPpass[7]='1110' 
CKPpass[8]='1210'
CKPpass[9]='1700' 

#Password: Servertruststore
STSpass='server'

#Password: Serverkeystore
SKSpass='server'

#Password: Key-pair (Server)
SKPpass='server'

echo "Creating X.509 CA certificate, private key = CAkey.pem"
echo -e '.\n.\n.\n.\n.\nCA\n.\n' | openssl req -x509 -newkey rsa:1024 -keyout CAkey.pem -out CA.pem -passout pass:${CApass}

echo "Creating truststore for client, clienttruststore, that contains CA"
yes | keytool -import -file CA.pem -alias CA -keystore clienttruststore -storepass ${CTSpass}

echo "Creating keypairs and keystores (Client)"
for (( i=0; i<${#person[@]}; i++ ))
do
	ks=${person[$i]}-'store'
	pass=${passwd[$i]}
	keytool -genkeypair -alias keypair -keystore ${ks} -dname "CN=${person[$i]}" -storepass ${pass} -keypass ${CKPpass[$i]}
done

echo "Creating CSRs for clientkeystores"
for (( i=0; i<${#person[@]}; i++ ))
do
	ks=${person[$i]}-'store'
	CSR='CSR'-${person[$i]}
	pass=${passwd[$i]}
	keytool -certreq -alias keypair -keystore ${ks} -file ${CSR} -storepass ${pass} -keypass ${CKPpass[$i]}
done

echo "CA signing CSRs"
for (( i=0; i<${#person[$i]}; i++))
do
	CSR='CSR'-${person[$i]}
	openssl x509 -req -in ${CSR} -CA CA.pem -CAkey CAkey.pem -out signed${CSR}.pem -CAcreateserial -passin pass:${CApass}
done

echo "Importing certificate chains into clientkeystores"
for (( i=0; i<${#person[$i]}; i++))
do
	ks=${person[$i]}-'store'
        sigCSR='signedCSR'-${person[$i]}.'pem'
	pass=${passwd[$i]}
	yes | keytool -importcert -alias CA -file CA.pem -keystore ${ks}  -storepass ${pass}
	keytool -importcert -alias keypair -file ${sigCSR} -keystore ${ks} -storepass ${pass} -keypass ${CKPpass[$i]}
done


# SERVER

echo "Creating keypair, CN = server"
keytool -genkeypair -alias keypair -keystore serverkeystore -dname "CN=server" -storepass ${SKSpass} -keypass ${SKPpass}

echo "Creating CSR for serverkeystore, CSR-server"
keytool -certreq -alias keypair -keystore serverkeystore -file CSR-server -storepass ${SKSpass} -keypass ${SKPpass}

echo "CA signing CSR-server"
openssl x509 -req -in CSR-server -CA CA.pem -CAkey CAkey.pem -out signedCSR-server.pem -CAcreateserial -passin pass:${CApass}

echo "Imports the certificate chain into serverkeystore"
yes | keytool -importcert -alias CA -file CA.pem -keystore serverkeystore -storepass ${SKSpass}
keytool -importcert -alias keypair -file signedCSR-server.pem -keystore serverkeystore -storepass ${SKSpass} -keypass ${SKPpass}

# echo "Printing serverkeystore"
# keytool -list -keystore serverkeystore -v -keypass password

echo "Creating serverside truststore"
yes | keytool -import -file CA.pem -alias CA -keystore servertruststore -storepass ${STSpass}

#!/bin/bash -e
ls
echo "********************************************************"
echo "********************************************************"
echo This script will build a Java Key Store
echo
echo You will need to have:
echo ---JDK installed
echo ---OpenSSL
echo '---SAVE.OpenSSL.cnf file (modify this to meet your needs'
echo
echo Usage: ./build_jks.sh {directory to use }
echo "********************************************************"
echo "********************************************************"

BASE_DIR=security
#MY_CA_BASE_DIR=TEST1
PREFIX=jboss

TEMP=$1

if [ -z $1 ] 
then
    echo you must supply a directory for the jks store
    echo this directory is "relative to" the current directory
    echo Usage: ./build_jks.sh {directory to use }
else
    if [ -z $2 ]
    then
       echo no specific keystore prefix defined using ${PREFIX}
    else
      PREFIX=$2
      echo using prefix $2
    fi

    BASE_DIR=$1
    echo BASE_DIR is: $BASE_DIR

    BASE_DIR_RELATIVE=$(pwd)
    echo $BASE_DIR_RELATIVE
    mkdir $BASE_DIR
    cd $BASE_DIR
    BASE_DIR=$(pwd)
    echo "NEW BASE_DIR" $BASE_DIR
    export MY_CA_BASE_DIR=$BASE_DIR
    echo MY_CA_BASE_DIR is: $MY_CA_BASE_DIR
fi

#/C=US/ST=NC/L=Raleigh/OU=OpenShift CDK/O=${ORG}/CN=Demo Root Certificate Authority
CA_C="US"
CA_ST="NC"
CA_L="RALEIGH"
CA_OU="ENGINEERING"
CA_CN="PROGRAM_X"
CA_O="Demo CA"

# -dname CN=rhel_${PREFIX}, OU=${SERVER_OU}, O=${SERVER_O}, L=${SERVER_L}, S=${SERVER_S}, C=US
SERVER_C=$CA_C
SERVER_ST=$CA_ST
SERVER_L=$CA_L
SERVER_OU=$CA_OU
SERVER_O=$CA_O
SERVER_CN="rhel_"${PREFIX}

mkdir -vp $MY_CA_BASE_DIR/myCA/{certs,private}
cd $MY_CA_BASE_DIR/myCA
echo 1000 > serial; touch certindex.txt
#
# you have to have the OpenSSL Configration file saved someplace
# it should already be configured for our specific env
#
cp $MY_CA_BASE_DIR/../SAVE_openssl.cnf openssl.base

sed -e "s|CA_BASE_DIR|$MY_CA_BASE_DIR/myCA|g" openssl.base > openssl.conf

rm openssl.base

echo "++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++"
echo "Done with preliminary configuration"
ls -la
#cat openssl.conf
echo "++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++"

echo "++++++++++++++++++++++++++++++++++++++"
tree
echo "Create OpenSSL CA Request"
#
echo "++++++++++++++++++++++++++++++++++++++"
openssl req -new -x509 -days 3650 \
 -keyout private/cakey.pem \
 -out cacert.pem \
 -subj "/C=${CA_C}/ST=${CA_ST}/L=${CA_L}/OU=${CA_OU}/O=${CA_O}/CN=${CA_CN}" \
 -config openssl.conf \
 -passout pass:"password"

echo "++++++++++++++++++++++++++++++++++++++"
tree
echo "Initialize CA"
echo "++++++++++++++++++++++++++++++++++++++"
openssl ca -config openssl.conf -passin pass:"password"

#echo "++++++++++++++++++++++++++++++++++++++"
#echo "Done with initializing openss Root CA
#echo "++++++++++++++++++++++++++++++++++++++"

#
# change to BASE_DIR
#
cd $MY_CA_BASE_DIR
ls
echo "++++++++++++++++++++++++++++++++++++++"
echo "Create Trust Keystore:["${PREFIX}TrustKeystore.jks "]"
echo "++++++++++++++++++++++++++++++++++++++"
keytool -file $MY_CA_BASE_DIR/myCA/cacert.pem -importcert -trustcacerts \
 -keystore ${PREFIX}TrustKeystore.jks -storepass password -noprompt

keytool -v -list -keystore ${PREFIX}TrustKeystore.jks -storepass password

echo "++++++++++++++++++++++++++++++++++++++"
echo "Create Server Identity Keystore"
echo "++++++++++++++++++++++++++++++++++++++"

keytool -genkey -alias ${PREFIX}alias -keyalg RSA -sigalg SHA256withRSA \
 -keypass password -keystore ${PREFIX}IdentityKeystore.jks \
 -storepass password \
 -dname "CN=${SERVER_CN}, OU=${SERVER_OU}, O=${SERVER_O}, L=${SERVER_L}, ST=${SERVER_ST}, C=US"

keytool -v  -list -keystore ${PREFIX}IdentityKeystore.jks -storepass password

tree

echo "++++++++++++++++++++++++++++++++++++++"
echo "Create Server Certificate Signing Request CSR for the Identity keystore"
echo "++++++++++++++++++++++++++++++++++++++"

keytool -certreq -alias ${PREFIX}alias -file ${PREFIX}cert.req -keypass password \
 -keystore ${PREFIX}IdentityKeystore.jks -storepass password


echo "++++++++++++++++++++++++++++++++++++++"
echo "use openssl ca to sign Server jks cert request"
echo "++++++++++++++++++++++++++++++++++++++"

openssl ca -config myCA/openssl.conf -out ${PREFIX}cert.pem -notext \
 -md sha256 -batch -passin pass:"password" -infiles ${PREFIX}cert.req 

echo "++++++++++++++++++++++++++++++++++++++"
echo "create the Server cert chain "
echo "++++++++++++++++++++++++++++++++++++++"

cat ${PREFIX}cert.pem myCA/cacert.pem > ${PREFIX}certchain.pem

echo "++++++++++++++++++++++++++++++++++++++"
echo "import the Server cert chain into the Identity Trust Store "
echo "++++++++++++++++++++++++++++++++++++++"
keytool -import -alias ${PREFIX}alias -keypass password\
 -keystore ${PREFIX}IdentityKeystore.jks -storepass password \
 -noprompt \
 -file ${PREFIX}certchain.pem

keytool -v -list -keystore ${PREFIX}IdentityKeystore.jks -storepass password


echo "********************************************************"
echo " WARNING ... about to copy certs"
echo "********************************************************"
cp $MY_CA_BASE_DIR/${PREFIX}IdentityKeystore.jks ../../${PREFIX}-identity.ks
cp $MY_CA_BASE_DIR/${PREFIX}TrustKeystore.jks ../../${PREFIX}-trust.ts

echo ----
echo ----
echo ----

# -dname CN=client_${PREFIX}, OU=${CLIENT_OU}, O=${CLIENT_O}, L=${CLIENT_L}, S=${CLIENT_S}, C=US
CLIENT_C=$CA_C
CLIENT_ST=$CA_ST
CLIENT_L=$CA_L
CLIENT_OU=$CA_OU
CLIENT_OU2=Personnel
CLIENT_O=$CA_O
CLIENT_CN="client_"${PREFIX}

echo "++++++++++++++++++++++++++++++++++++++"
echo "Create Client Identity Keystore"
echo "++++++++++++++++++++++++++++++++++++++"

keytool -genkey -alias clientalias -keyalg RSA -sigalg SHA256withRSA \
 -keypass password -keystore clientIdentityKeystore.jks \
 -storepass password \
 -dname "CN=${CLIENT_CN}, OU=${CLIENT_OU}, OU=${CLIENT_OU2}, O=${CLIENT_O}, L=${CLIENT_L}, ST=${CLIENT_ST}, C=US"

keytool -v  -list -keystore clientIdentityKeystore.jks -storepass password

tree

echo "++++++++++++++++++++++++++++++++++++++"
echo "Create Client Certificate Signing Request CSR for the Identity keystore"
echo "++++++++++++++++++++++++++++++++++++++"

keytool -certreq -alias clientalias -file clientcert.req -keypass password \
 -keystore clientIdentityKeystore.jks -storepass password

echo "++++++++++++++++++++++++++++++++++++++"
echo "use openssl ca to sign Client jks cert request"
echo "++++++++++++++++++++++++++++++++++++++"

openssl ca -config myCA/openssl.conf -out clientcert.pem -notext \
 -md sha256 -batch -passin pass:"password" -infiles clientcert.req 

echo "++++++++++++++++++++++++++++++++++++++"
echo "create the Client cert chain "
echo "++++++++++++++++++++++++++++++++++++++"

cat clientcert.pem myCA/cacert.pem > clientcertchain.pem

echo "++++++++++++++++++++++++++++++++++++++"
echo "import the Client cert chain into the Identity Trust Store "
echo "++++++++++++++++++++++++++++++++++++++"
keytool -import -alias clientalias -keypass password\
 -keystore clientIdentityKeystore.jks -storepass password \
 -noprompt \
 -file clientcertchain.pem

keytool -v -list -keystore clientIdentityKeystore.jks -storepass password

echo "++++++++++++++++++++++++++++++++++++++"
echo "create a PKCK12 client cert for use by Firefox"
echo "++++++++++++++++++++++++++++++++++++++"
keytool -importkeystore -srckeystore clientIdentityKeystore.jks \
        -srcstorepass password \
        -destkeystore client.p12 -deststoretype PKCS12 \
        -deststorepass password -destkeypass password


echo "********************************************************"
echo "INFO  ... about to copy client certs"
echo "********************************************************"
cp $MY_CA_BASE_DIR/clientIdentityKeystore.jks ../../client-identity.ks
cp $MY_CA_BASE_DIR/client.p12 ../../client.p12


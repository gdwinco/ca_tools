# ca_tools
A script to create test/demo CA signed certs using openssl

build_jks.sh -- builds your custom certificates signed by your demo certificate authority

SAVE_openss.cnf -- custom settings for your certificate and CA. You edit this file

Usage: ./build_jks.sh {keystore-directory} {prefix}
- where keystore-directory is created releative to the directory you execute build_jks.sh in

./build_jks.sh CERTS
	
	CERTS/
	├── jbossIdentityKeystore.jks
	├── jbossTrustKeystore.jks
	├── jbosscert.pem
	├── jbosscert.req
	├── jbosscertchain.pem
	└── myCA
    	├── cacert.pem
    	├── certindex.txt
    	├── certindex.txt.attr
    	├── certindex.txt.old
    	├── certs
    	│   └── 1000.pem
    	├── openssl.conf
    	├── private
    	│   └── cakey.pem
   	 	├── serial
    	└── serial.old
    	
 ./build_jks.sh CUSTOM teiid
 
 	CUSTOM/
	├── myCA
	│   ├── cacert.pem
	│   ├── certindex.txt
	│   ├── certindex.txt.attr
	│   ├── certindex.txt.old
	│   ├── certs
	│   │   └── 1000.pem
	│   ├── openssl.conf
	│   ├── private
	│   │   └── cakey.pem
	│   ├── serial
	│   └── serial.old
	├── teiidIdentityKeystore.jks
	├── teiidTrustKeystore.jks
	├── teiidcert.pem
	├── teiidcert.req
	└── teiidcertchain.pem
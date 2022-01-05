#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty

# Protocols to test, actually ssl3 is not supported anymore
protocols="ssl3 tls1 tls1_1 tls1_2 tls1_3"
# Timeout in seconds, put e.g. 2 or 5 on slower servers / connections
timeout=1

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "Simple Server Chiphers Scanner based on openssl."
			echo ""
			echo "Execution:"
			echo "checkServerCiphers.sh <host>:<port> <parameter>"
			echo ""
			echo "  -v        verbose Protocol output."
			echo "  -vv       verbose Ciphers output."
			echo "  -vvv      verbose OpenSSL output.
"
			echo "  -s        Test only supported Ciphers
            this is defalut setting.
"
			echo "  -all      Test all (also unsupported) Ciphers."
			echo "  -allNull  Test all Ciphers (also unsupported),
            even with zero encryption.
"
			exit 0
			;;
		*)
		break
		;;
	esac
done

# Connection Test

if [ "$(curl -skL -m $timeout -w "%{http_code}\n" https://$1 -o /dev/null)" -eq 000 ]; then

	echo "ERROR - Could not connect to: https://$1"

	exit 1

fi

opensslCiphers () {

	#openssl ciphers 'ALL:eNULL' | tr ':' ' '

	# Test only Supported Ciphers
	[[ $1 == "" || $1 == "-s" || $2 == "-s" ]] && { ciphersList="$(openssl ciphers -s -$protocol 2>/dev/null | tr ':' ' ')" ; }

	# Test All Ciphers
	[[ $1 == "-all" || $2 == "-all" ]] && { ciphersList="$(openssl ciphers -$protocol 2>/dev/null | tr ':' ' ')" ; }

	# Test All Ciphers with zero encryption
	[[ $1 == "-allNull" || $2 == "-allNull" ]] && { ciphersList="$(openssl ciphers 'ALL:eNULL' 2>/dev/null | tr ':' ' ')" ; }

}

echo -e "Now scanning:\t$1"

found="Results for $1:"

# TLS Scan
for protocol in $protocols; do

	[[ $2 == "-v" || $2 == "-vv" || $2 == "-vvv" ]] && { echo -e "Checking:\t$protocol ..."; }

#	for cipher in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do

	opensslCiphers $2 $3

	[[ $2 == "-vv" || $2 == "-vvv" ]] && { echo -e "Following Ciphers will be tested:\t$ciphersList"; }

	for cipher in $ciphersList; do

		[[ $2 == "-vv" || $2 == "-vvv" ]] && { echo -e "Checking:\t$protocol with Cipher:\t$cipher"; }

		if [[ $2 == "-vvv" ]]; then

			timeout $timeout openssl s_client -connect $1 -cipher $cipher -$protocol < /dev/null && \
			found="${found}\n$(echo -e "Protocol:\t$protocol with Cipher:\t$cipher")" && \
			echo -e "Found:    \t$protocol with Cipher:\t$cipher"

		else

			timeout $timeout openssl s_client -connect $1 -cipher $cipher -$protocol < /dev/null > /dev/null 2>&1 && \
			found="${found}\n$(echo -e "Protocol:\t$protocol with Cipher:\t$cipher")" && \
			[[ $2 == "-vv" || $2 == "-vvv" ]] && { echo -e "Found:    \t$protocol with Cipher:\t$cipher"; }

		fi

	done

done

echo -e "${found}"

exit 0

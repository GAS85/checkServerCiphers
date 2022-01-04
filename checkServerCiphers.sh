#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty

protocols="ssl3 tls1 tls1_1 tls1_2 tls3"
timeout=5

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "Simple Server Chiphers Scanner based on openssl."
			echo ""
			echo "Execution:"
			echo "checkServerCiphers.sh <host>:<port> <parameter>"
			echo ""
			echo " -v    verbose Protocol output."
			echo " -vv   verbose Ciphers output."
			exit 0
			;;
		*)
		break
		;;
	esac
done

# Connection Test

if [ "$(curl -sL -m $timeout -w "%{http_code}\n" $1 -o /dev/null)" -eq 000 ]; then

	echo "ERROR - Could not connect to: $1"

	exit 1

fi

echo -e "Now scanning:\t$1"

found="Results for $1:"

# TLS Scan
for protocol in $protocols; do

	[[ $2 == "-v" || $2 == "-vv" ]] && { echo -e "Checking:\t$protocol ..."; }

	for cipher in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do

		[[ $2 == "-vv" ]] && { echo -e "Checking:\t$protocol with Cipher:\t$cipher"; }

		timeout $timeout openssl s_client -connect $1 -cipher $cipher -$protocol < /dev/null > /dev/null 2>&1 && \
		found="${found}\n$(echo -e "Protocol:\t$protocol with Cipher:\t$cipher")" && \
		[[ $2 == "-vv" ]] && { echo -e "Found:    \t$protocol with Cipher:\t$cipher"; }

	done

done

echo -e "${found}"

exit 0
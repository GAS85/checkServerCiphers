#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty

# TLS Protocols to test
protocols="1.1 1.2 1.3"
# Timeout in seconds, put e.g. 5 on slower servers / connections
timeout=2

while test $# -gt 0; do
	case "$1" in
		-h,--help)
			echo "Simple Server Chiphers Scanner based on openssl and curl."
			echo ""
			echo "Usage: ./checkServerCiphers.sh <protocol>://<host>:<port> [options] [ciphers]"
			echo "Example:"
			echo "  ./checkServerCiphers.sh https://myserver.com:8080"
			echo "  ./checkServerCiphers.sh https://myserver.com -v ALL:eNULL"
			echo ""
			echo "  <protocol>   Could be HTTPS, FTPS, IMAPS, SMTPS, etc."
			echo "  <host>	   FQDN that you need to test"
			echo "  <port>	   Port that you need to test"
			echo ""
			echo "Options:"
			echo "  -v		   verbose Protocol output."
			echo "  -vv		  verbose Ciphers output."
			echo "  -vvv		 verbose Curl output."
			echo ""
			echo "Ciphers:"
			echo "  ALL		  Test ALL Ciphers, this is defalut setting."
			echo "  ALL:eNULL	Test also Ciphers with zero encryption."
			echo "  HIGH:MEDIUM  etc. Please refer to https://curl.se/docs/ssl-ciphers.html
			   for more information."
			exit 0
			;;
		*)
		break
		;;
	esac
done

# Set different Variables
linkToTest=$1

[[ $2 == "-v" || $2 == "-vv" || $2 == "-vvv" ]] && { verboseLvL="$(echo $2 | wc -m)" ; cipherString=$3 ; } || { verboseLvL=0 ; cipherString=$2 ; }

[[ "$verboseLvL" == "5" ]] && { curlOptions="-kl" ; } || { curlOptions="-skl -o /dev/null"; }

[[ -z $cipherString ]] && { cipherString="ALL" ; }

curlTLSOptions="--ciphers"

found="Results for \t$linkToTest"

# Connectivity Test

if [ "$(curl $curlOptions -m $timeout -w "%{http_code}\n" --ssl-reqd $linkToTest)" -eq 000 ]; then

	echo "ERROR - Could not connect to: $linkToTest"

	exit 1

fi

opensslCiphers () {

	# Get list of Ciphers based on User input
	ciphersList="$(openssl ciphers $cipherString 2>/dev/null | tr ':' ' ')"

}

echo -e "Now scanning:\t$linkToTest with '$cipherString' set of Ciphers"

# TLS Scan
for protocol in $protocols; do

	[[ "$verboseLvL" -ge 3 ]] && { echo -e "Checking:\tTLSv$protocol ..."; }

	opensslCiphers

	[[ "$verboseLvL" -ge 4 ]] && { echo -e "Following Ciphers will be tested:\t$ciphersList"; }

	for cipher in $ciphersList; do

		[[ "$verboseLvL" -ge 4 ]] && { echo -e "Checking:\ttTLSv$protocol with Cipher:\t$cipher"; }

		# change Options Syntax when TLS 1.3 being used, otherwise will accept all because of Server negotioation
		[[ "$protocol" == "1.3" ]] && { curlTLSOptions="--tls13-ciphers" ; }

		if [ "$(curl $curlOptions -m $timeout -w "%{http_code}\n" $linkToTest --tlsv$protocol --tls-max $protocol $curlTLSOptions $cipher)" -gt 000 ]; then

			found="${found}\n$(echo -e "Protocol:\tTLSv$protocol with Cipher:\t$cipher")"

			[[ "$verboseLvL" -ge 3 ]] && { echo -e "Found:	\tTLSv$protocol with Cipher:\t$cipher" ; }

		fi

	done

done

# Show Results
echo -e "${found}"

exit 0

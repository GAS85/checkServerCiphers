#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty

# TLS Protocols to test
protocols="1.1 1.2 1.3"
protocolsOpenssl="tls1 tls1_1 tls1_2 tls1_3"
# Timeout in seconds, put e.g. 5 on slower servers / connections
timeout=2

while getopts ":hvoc:l:" option; do
	case $option in
		h)	# Help
			echo "Simple Server Chiphers Scanner based on openssl and curl."
			echo ""
			echo "Usage: ./checkServerCiphers.sh [options] [ciphers] -l <protocol>://<host>:<port>"
			echo "Example:"
			echo "  ./checkServerCiphers.sh -l https://myserver.com:8080"
			echo "  ./checkServerCiphers.sh -l myserver.com:8080 -o"
			echo "  ./checkServerCiphers.sh -vv -c ALL:eNULL -l https://myserver.com"
			echo ""
			echo "Options:"
			echo "  -l              Full link to test with:"
			echo "    <protocol>    Curl only, could be HTTPS, FTPS, IMAPS, SMTPS, etc.
                  shuold not be set when '-o' been used."
			echo "    <host>        FQDN that you need to test"
			echo "    <port>        Port that you need to test"
			echo "  -o              use OpenSSL instead of Curl. Default use Curl."
			echo "  -v              verbose Protocol output."
			echo "  -vv             verbose Ciphers output."
			echo "  -vvv            verbose Curl output."
			echo ""
			echo "Ciphers:"
			echo "  -c              Set Ciphers list to test, default 'ALL'. E.g.:"
			echo "  -c ALL          Test ALL Ciphers, this is default setting."
			echo "  -c ALL:eNULL    Test also Ciphers with zero encryption."
			echo "  -c HIGH:MEDIUM  etc. Please refer to https://curl.se/docs/ssl-ciphers.html
                  for more information."
			exit 0
			;;
		l)	# Link to test
			linkToTest="$OPTARG"
			;;
		v)	# Verbose
			((verboseLvL++));
			;;
		o)	# Use OpenSSL
			tool="openssl"
			protocols="$protocolsOpenssl"
			;;
		c)	# Set Ciphers
			cipherString="$OPTARG"
			;;
		\?)
			break
			;;
	esac
done

# Set different Variables
[[ -z $linkToTest ]] && { exit 0 ; }

[[ "$verboseLvL" -ge "3" ]] && { curlOptions="-kl" ; } || { curlOptions="-skl -o /dev/null"; }

[[ -z $cipherString ]] && { cipherString="ALL" ; }

# Set default tool to curl
[[ -z $tool ]] && { tool="curl" ; }

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

	[[ "$verboseLvL" -ge 1 && "$tool" == "curl" ]] && { echo -e "Checking:\tTLSv$protocol ..."; }
	[[ "$verboseLvL" -ge 1 && "$tool" == "openssl" ]] && { echo -e "Checking:\t$protocol ..."; }

	opensslCiphers

	[[ "$verboseLvL" -ge 2 ]] && { echo -e "Following Ciphers will be tested:\t$ciphersList"; }

	for cipher in $ciphersList; do

		[[ "$verboseLvL" -ge 2 && "$tool" == "curl" ]] && { echo -e "Checking:\tTLSv$protocol with Cipher:\t$cipher"; }
		[[ "$verboseLvL" -ge 2 && "$tool" == "openssl" ]] && { echo -e "Checking:\t$protocol with Cipher:\t$cipher"; }

		if [ "$tool" == "curl" ]; then

			# change Options Syntax when TLS 1.3 being used, otherwise will accept all because of Server negotioation
			[[ "$protocol" == "1.3" ]] && { curlTLSOptions="--tls13-ciphers" ; }

			if [ "$(curl $curlOptions -m $timeout -w "%{http_code}\n" $linkToTest --tlsv$protocol --tls-max $protocol $curlTLSOptions $cipher)" -gt 000 ]; then

				found="${found}\n$(echo -e "Protocol:\tTLSv$protocol with Cipher:\t$cipher")"

				[[ "$verboseLvL" -ge 2 ]] && { echo -e "Found:	\tTLSv$protocol with Cipher:\t$cipher" ; }

			fi

		else

			if [[ "$verboseLvL" -ge 3 ]]; then

				timeout $timeout openssl s_client -connect $linkToTest -cipher $cipher -$protocol < /dev/null && \
				found="${found}\n$(echo -e "Protocol:\t$protocol with Cipher:\t$cipher")" && \
				echo -e "Found:    \t$protocol with Cipher:\t$cipher"

			else

				timeout $timeout openssl s_client -connect $linkToTest -cipher $cipher -$protocol < /dev/null > /dev/null 2>&1 && \
				found="${found}\n$(echo -e "Protocol:\t$protocol with Cipher:\t$cipher")" && \
				[[ "$verboseLvL" -ge 2 ]] && { echo -e "Found:    \t$protocol with Cipher:\t$cipher"; }

			fi

		fi

	done

done

# Show Results
echo -e "${found}"

exit 0

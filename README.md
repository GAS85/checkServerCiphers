# Using of checkServerCiphers

Using OpenSSL to determine which Ciphers are Enabled on a Server.
This script will goes over all supported Protocols and Ciphers with openssl and report if some of them are supported by Server.

```
checkServerCiphers.sh <host>:<port> <parameter>
    -v    verbose Protocol output.
	-vv   verbose Ciphers output.
```

Executuin will take a while...

## Example

### Standart output

```
checkServerCiphers.sh google.com
Now scanning:	google.com

```

### Verbose output

```
checkServerCiphers.sh google.com -v
Now scanning:	google.com
Checking:	ssl3 ...
Checking:	tls1 ...
Checking:	tls1_1 ...
Checking:	tls1_2 ...
Checking:	tls1_3 ...
```
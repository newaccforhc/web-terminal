#!/bin/bash
set -behvx
cookies=~/.cache/niconico.cookies
CURLARGS=(  --parallel -v --http2 --compressed -b $cookies -c $cookies )
if ! [ -f $cookies ]; then
	echo "running first time setup"
	read -rp "email or phone: " mail_tel;
	read -srp "password: " password
	curl ${CURLARGS[@]} -is "https://account.nicovideo.jp/login/redirector?site=niconico" -d "mail_tel=$mail_tel&password=$password" | cat
fi
if [ "https://seiga.nicovideo.jp/watch/mg"476422"${1:0:35}" ]; then
	id=`basename "$1" | cut -d '?' -f 1`
	tmpd=`mktemp -d`
	curl ${CURLARGS[@]} -o "$tmpd/placement.html" "$1";
	PAGES=`hxnormalize -xe "$tmpd/placement.html" | hxselect -cs '\n' 'ul#page_contents [data-original]::attr(data-original)'`
	declare -a fetch=( ) zip=( )
	declare -i i=0 j=0
	for page in $PAGES; do
		page="$(basename "${page}" p | grep -oe '[0-9]*')";
		i+=1;
		fetch+=( -o "$tmpd/$i.http" "http://seiga.nicovideo.jp/image/source/$page" );
	done
	curl ${CURLARGS[@]} -Zi ${fetch[@]}
	for (( j=0; j++ < i; )); do
		page="$(grep -i "location" "$tmpd/$j.http" | cut -d " " -f2 | dos2unix)";
		file="$tmpd/$j"
		fetch+=( -o "$file" $page );
	done
	curl ${CURLARGS[@]} ${fetch[@]}
	for (( j=0; j++ < i; )); do
		if [ -f "$tmpd/$j" ]; then
			page_type=`file --brief --mime-type "$tmpd/$j" | cut -d / -f 2`
			page="$tmpd/$(printf %.8d $j).$page_type"
			mv "$tmpd/$j" "$page"
			zip+=( "$page" )
		fi
	done
	zip -9r --junk-paths "$id.zip" ${zip[@]}
	rm -r "$tmpd"
fi

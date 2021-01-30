#/bin/bash

function cleanup {
	echo "Clean up"
	rm -R $TMP_DIR
}

EMBEDDED_MOBILEPROVISION="$1"
OLD_IPA="$2"
NEW_IPA="$3"

if [ "$1" == "" -o  "$2" == "" -o  "$3" == "" ]; then
	echo "Usage $0 EMBEDDED_MOBILEPROVISION OLD_IPA NEW_IPA"

	exit 1
fi

if [ -e "$NEW_IPA" ]; then
	echo "File $NEW_IPA exists, overwrite? y/[n]"

	read CONT

	[ "$CONT" != 'y' ] && exit 0

	rm "$NEW_IPA"
fi


TMP_DIR=`mktemp -d`
trap cleanup EXIT

echo "Available provisioning profiles:"

security find-identity -v -p codesigning

echo -en "\nCopy and paste profile to use without quotes:\nPROFILE="
read PROFILE

echo -e "\nSelected profile: \"$PROFILE\""
echo "Continue? ([y]/n)"

read CONT

[ "$CONT" == 'n' ] && exit 0

echo -e "\nUsing entitlements:"
security cms -D -i "$EMBEDDED_MOBILEPROVISION" > "$TMP_DIR/new_provision.plist"
/usr/libexec/PlistBuddy -x -c 'Print :Entitlements' "$TMP_DIR/new_provision.plist" | tee "$TMP_DIR/new_entitlements.plist"

echo -e "\nUnzipping $OLD_IPA"
unzip -qd "$TMP_DIR/old" "$OLD_IPA"

APP_DIR=`find "$TMP_DIR/old" -depth 2 -type d -name "*.app"`

echo -e "\nRemoving old signatures"
rm -vR "$APP_DIR/_CodeSignature"

CFBUNDLEEXECUTABLE=`/usr/libexec/PlistBuddy -c "print CFBundleExecutable" "$APP_DIR/Info.plist"`

echo -e "\nSigning files"

codesign -f -s "$PROFILE" --entitlements "$TMP_DIR/new_entitlements.plist" "$APP_DIR/"
[ -d "$APP_DIR/Frameworks" ] && codesign -f -s "$PROFILE" --entitlements "$TMP_DIR/new_entitlements.plist" "$APP_DIR/Frameworks/*"
codesign -f -s "$PROFILE" --entitlements "$TMP_DIR/new_entitlements.plist" "$APP_DIR/$CFBUNDLEEXECUTABLE" 

echo -e "\nCreating new IPA"

pushd "$TMP_DIR/old/"
zip -qr "$OLDPWD/$NEW_IPA" "./Payload"
popd

echo -e "\nInstall IPA using: ios-deploy -b \"$NEW_IPA\""



#!/bin/sh
# Build the ChocoHub Wallet AppImage (python-appimage + appimagetool).
set -e
cd "$(dirname "$0")"

WORK=/tmp/opencode
BASE_URL="https://github.com/niess/python-appimage/releases/download/python3.13/python3.13.14-cp313-cp313-manylinux_2_28_x86_64.AppImage"
APPDIR="$WORK/pyroot/squashfs-root"
APPT=$(ls "$WORK"/appimagetool/squashfs-root/usr/bin/appimagetool 2>/dev/null)

echo "==> 1/5 fetch tools"
if [ ! -f "$WORK/python313.AppImage" ]; then
    curl -sL -o "$WORK/python313.AppImage" "$BASE_URL"
fi
if [ ! -x "$WORK/appimagetool.AppImage" ]; then
    curl -sL -o "$WORK/appimagetool.AppImage" \
        "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$WORK/appimagetool.AppImage"
fi

echo "==> 2/5 extract base python"
if [ ! -d "$APPDIR" ]; then
    mkdir -p "$WORK/pyroot"
    (cd "$WORK/pyroot" && "$WORK/python313.AppImage" --appimage-extract >/dev/null)
fi
if [ ! -d "$WORK/appimagetool/squashfs-root" ]; then
    mkdir -p "$WORK/appimagetool"
    (cd "$WORK/appimagetool" && "$WORK/appimagetool.AppImage" --appimage-extract >/dev/null)
fi

echo "==> 3/5 install deps"
"$APPDIR/usr/bin/python3.13" -m pip install -q --no-cache-dir cryptography flask segno

echo "==> 4/5 assemble app"
rm -rf "$APPDIR/opt/chocohub"
mkdir -p "$APPDIR/opt/chocohub"
cp wallet.py "$APPDIR/opt/chocohub/"
cp -r chocohub_gui "$APPDIR/opt/chocohub/"
# real AppRun (base ships AppRun -> usr/bin/python3.13 wrapper, replace entirely)
rm -f "$APPDIR/AppRun" "$APPDIR/usr/bin/python3.13"
ln -s ../../opt/python3.13/bin/python3.13 "$APPDIR/usr/bin/python3.13"
rm -f "$APPDIR/python3.13.14.desktop" "$APPDIR/python.png"
cp build/chocohub-wallet.desktop "$APPDIR/chocohub-wallet.desktop"
cp build/AppRun "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp build/chocohub-wallet.png "$APPDIR/chocohub-wallet.png"
cp build/cacert.pem "$APPDIR/opt/chocohub/cacert.pem"

echo "==> 5/5 package AppImage"
mkdir -p build
rm -f build/ChocoHub-Wallet-x86_64.AppImage ChocoHub-Wallet-x86_64.AppImage
(cd "$WORK/pyroot" && PATH="$WORK/appimagetool/squashfs-root/usr/bin:$PATH" \
    ARCH=x86_64 "$APPT" squashfs-root \
    "/home/chocoetom/Documentos/Default Project/ChocoHub-Wallet-x86_64.AppImage")
cp ChocoHub-Wallet-x86_64.AppImage build/

ls -la ChocoHub-Wallet-x86_64.AppImage

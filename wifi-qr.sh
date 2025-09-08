#!/bin/bash

# Check if qrencode is installed
if ! command -v qrencode &> /dev/null; then
    echo "qrencode not found. Please install it (e.g., sudo apt install qrencode)."
    exit 1
fi

# Require sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script needs sudo to read Wi-Fi passwords."
    echo "👉 Run it as: sudo $0"
    exit 1
fi

# Get current Wi-Fi SSID
SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

if [ -z "$SSID" ]; then
    echo "No active Wi-Fi connection found."
    exit 1
fi

# Get Wi-Fi password
PASS=$(grep -r '^psk=' /etc/NetworkManager/system-connections/ | grep "$SSID" | head -n1 | cut -d= -f2)

if [ -z "$PASS" ]; then
    echo "No password found for SSID: $SSID (maybe it's open or stored elsewhere)."
    exit 1
fi

echo "SSID: $SSID"
echo "Password: $PASS"

# Create Wi-Fi QR code string (WPA/WPA2 assumed; change T=WEP if needed)
QRSTRING="WIFI:T:WPA;S:${SSID};P:${PASS};;"

# Display in terminal
qrencode -t ANSIUTF8 "$QRSTRING"

# Create output folder
OUTDIR="./qr-codes"
mkdir -p "$OUTDIR"

# Save as qr-codes/SSID.png (sanitize SSID for filename)
FILENAME="$(echo "$SSID" | tr -cd '[:alnum:]._-').png"
qrencode -o "$OUTDIR/$FILENAME" "$QRSTRING"

echo "✅ QR code saved as $OUTDIR/$FILENAME"

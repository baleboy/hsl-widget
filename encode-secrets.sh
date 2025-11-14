#!/bin/bash

echo "=================================="
echo "GitHub Secrets Encoder for TestFlight"
echo "=================================="
echo ""

echo "This script will help you base64 encode your files for GitHub Secrets."
echo "After encoding, each value will be copied to your clipboard."
echo "Paste it into GitHub immediately before moving to the next file."
echo ""

# Function to encode and copy
encode_and_copy() {
    local file_path="$1"
    local secret_name="$2"

    if [ ! -f "$file_path" ]; then
        echo "❌ File not found: $file_path"
        echo "   Please enter the correct path."
        return 1
    fi

    echo "✅ Encoding: $file_path"
    base64 -i "$file_path" | pbcopy
    echo "📋 Copied to clipboard!"
    echo "🔑 GitHub Secret Name: $secret_name"
    echo ""
    echo "Now:"
    echo "  1. Go to: https://github.com/baleboy/hsl-widget/settings/secrets/actions"
    echo "  2. Click 'New repository secret'"
    echo "  3. Name: $secret_name"
    echo "  4. Value: Paste (Cmd+V)"
    echo "  5. Click 'Add secret'"
    echo ""
    read -p "Press ENTER when done to continue..."
    echo ""
}

# 1. Distribution Certificate
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1/4: Distribution Certificate (.p12)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Enter the full path to your .p12 file: " cert_path
encode_and_copy "$cert_path" "CERTIFICATES_P12"

# 2. Main App Provisioning Profile
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2/4: Main App Provisioning Profile"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This should be: HslWidget App Store.mobileprovision"
read -p "Enter the full path to the main app .mobileprovision file: " main_profile_path
encode_and_copy "$main_profile_path" "MAIN_PROVISIONING_PROFILE"

# 3. Widget Provisioning Profile
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3/4: Widget Extension Provisioning Profile"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This should be: HslWidget stopInfo App Store.mobileprovision"
read -p "Enter the full path to the widget .mobileprovision file: " widget_profile_path
encode_and_copy "$widget_profile_path" "WIDGET_PROVISIONING_PROFILE"

# 4. App Store Connect API Key
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4/4: App Store Connect API Key (.p8)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Enter the full path to your AuthKey_*.p8 file: " api_key_path
encode_and_copy "$api_key_path" "APP_STORE_CONNECT_API_KEY"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All files encoded!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You still need to manually add these text secrets:"
echo ""
echo "  Name: CERTIFICATE_PASSWORD"
echo "  Value: The password you set for your .p12 file"
echo ""
echo "  Name: APP_STORE_CONNECT_KEY_ID"
echo "  Value: Your API Key ID (e.g., ABC123DEF)"
echo ""
echo "  Name: APP_STORE_CONNECT_ISSUER_ID"
echo "  Value: Your Issuer ID (UUID format)"
echo ""
echo "  Name: KEYCHAIN_PASSWORD"
echo "  Value: Any secure random password (e.g., $(uuidgen))"
echo ""
echo "All secrets should be added at:"
echo "https://github.com/baleboy/hsl-widget/settings/secrets/actions"
echo ""

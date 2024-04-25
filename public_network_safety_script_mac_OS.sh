#!/usr/bin/env bash

# Function to install Homebrew if it's not installed
install_homebrew() {
    echo "Checking for Homebrew installation..."
    which brew > /dev/null
    if [ $? -ne 0 ]; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is already installed."
    fi
}

# Installing Homebrew
install_homebrew

# Step 1: Install the latest Bash using Homebrew
echo "Installing the latest version of Bash..."
brew install bash

# Step 2: Add the new Bash to allowed shells
NEW_BASH_PATH=$(brew --prefix)/bin/bash
echo "Adding new Bash to allowed shells..."
echo $NEW_BASH_PATH | sudo tee -a /etc/shells

# Step 3: Change the default shell for the user
echo "Changing the default shell to the new Bash..."
chsh -s $NEW_BASH_PATH

# Step 4: Install WireGuard
echo "Installing WireGuard..."
brew install wireguard-tools

# Step 5: Create configuration file if it doesn't exist
WG_CONFIG="/opt/homebrew/etc/wireguard/wg0.conf"
if [ ! -f "$WG_CONFIG" ]; then
    echo "Creating WireGuard configuration file..."
    sudo mkdir -p $(dirname $WG_CONFIG)
    sudo touch $WG_CONFIG
    echo "[Interface]
PrivateKey = <your-private-key>
Address = 10.200.200.1/24
DNS = 1.1.1.1

[Peer]
PublicKey = <peer-public-key>
AllowedIPs = 0.0.0.0/0
Endpoint = <peer-endpoint>:51820" | sudo tee $WG_CONFIG > /dev/null
    echo "Remember to replace placeholder values in $WG_CONFIG"
fi

# Step 6: Create a launch agent to start WireGuard at login
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.user.wireguard.wg0.plist"
echo "Creating launch agent for WireGuard..."
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>com.user.wireguard.wg0</string>
    <key>ProgramArguments</key>
    <array>
        <string>$NEW_BASH_PATH</string>
        <string>/opt/homebrew/bin/wg-quick</string>
        <string>up</string>
        <string>wg0</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>" > $LAUNCH_AGENT
launchctl load $LAUNCH_AGENT

echo "Setup complete. Please log out and back in for changes to take effect."

# Making the script executable automatically (assuming this script is named setup.sh and located in the current directory)
chmod +x "$(basename "$0")"
echo "Script has been made executable."

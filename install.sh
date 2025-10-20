#!/usr/bin/env bash
set -euo pipefail

# Nihilix Installation Script
# Automates the setup of a new host configuration with interactive prompts

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner
echo -e "${MAGENTA}"
cat << "EOF"
    _   _____ ____  ______    ______  __
   / | / /  _/ __ \/  _/ /   /  _/ |/ /
  /  |/ // // / / // // /    / / |   /
 / /|  // // /_/ // // /____/ / /   |
/_/ |_/___/_____/___/_____/___//_/|_|

EOF
echo -e "${CYAN}Nihilix Automated Installation Script${NC}"
echo -e "${CYAN}======================================${NC}\n"

# Check if running on NixOS
if [[ ! -f /etc/NIXOS ]]; then
    echo -e "${RED}Error: This script must be run on NixOS!${NC}"
    echo "Please boot into NixOS first, then run this script."
    exit 1
fi

# Check if nixos-rebuild is available
if ! command -v nixos-rebuild >/dev/null 2>&1; then
    echo -e "${RED}Error: nixos-rebuild not found!${NC}"
    exit 1
fi

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: git is not installed. Installing git...${NC}"
    nix-shell -p git --run "echo 'Git installed temporarily'"
fi

echo -e "${GREEN}✓ Running on NixOS${NC}\n"

# Function to prompt for input with default value
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    local optional="${3:-false}"
    local result

    if [[ -n "$default_value" ]]; then
        read -p "$(echo -e ${CYAN}${prompt_text}${NC} [${YELLOW}${default_value}${NC}]: )" result
        echo "${result:-$default_value}"
    elif [[ "$optional" == "true" ]]; then
        read -p "$(echo -e ${CYAN}${prompt_text}${NC}: )" result
        echo "$result"
    else
        read -p "$(echo -e ${CYAN}${prompt_text}${NC}: )" result
        while [[ -z "$result" ]]; do
            read -p "$(echo -e ${RED}This field is required.${NC} ${CYAN}${prompt_text}${NC}: )" result
        done
        echo "$result"
    fi
}

# Function to prompt yes/no
confirm() {
    local prompt_text="$1"
    local default="${2:-n}"
    local result

    if [[ "$default" == "y" ]]; then
        read -p "$(echo -e ${CYAN}${prompt_text}${NC} [${GREEN}Y${NC}/${RED}n${NC}]: )" result
        result="${result:-y}"
    else
        read -p "$(echo -e ${CYAN}${prompt_text}${NC} [${RED}y${NC}/${GREEN}N${NC}]: )" result
        result="${result:-n}"
    fi

    [[ "$result" =~ ^[Yy]$ ]]
}

# Welcome message
echo -e "${BLUE}This script will help you set up Nihilix on your system.${NC}"
echo -e "${BLUE}It will ask you a few questions and then configure everything automatically.${NC}\n"

# Detect current hostname
CURRENT_HOSTNAME=$(hostname)
echo -e "${GREEN}Detected current hostname: ${YELLOW}${CURRENT_HOSTNAME}${NC}\n"

# Collect configuration information
echo -e "${MAGENTA}=== Host Configuration ===${NC}\n"

HOSTNAME=$(prompt "Hostname" "$CURRENT_HOSTNAME")
USERNAME=$(prompt "Username" "$USER")

# Detect timezone
if [[ -f /etc/timezone ]]; then
    DETECTED_TZ=$(cat /etc/timezone)
elif [[ -L /etc/localtime ]]; then
    DETECTED_TZ=$(readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||')
else
    DETECTED_TZ="Europe/Stockholm"
fi

TIMEZONE=$(prompt "Timezone (e.g., Europe/Stockholm, America/New_York)" "$DETECTED_TZ")
LOCATION=$(prompt "Location (e.g., Sweden, USA)" "Sweden")

echo ""
echo -e "${MAGENTA}=== Localization ===${NC}\n"

# Ask for keyboard layout with better guidance
echo -e "${CYAN}Common keyboard layouts:${NC}"
echo "  us (US English)"
echo "  uk (UK English)"
echo "  se (Swedish)"
echo "  sv (Swedish - alternative)"
echo "  de (German)"
echo "  fr (French)"
echo "  es (Spanish)"
echo "  no (Norwegian)"
echo "  dk (Danish)"
echo ""

KEYBOARD_INPUT=$(prompt "Keyboard layout" "us")

# NixOS needs TWO keyboard layout values:
# 1. keyboardLayout - for X11/Wayland/Hyprland
# 2. consoleKeyMap - for console (different naming)
case "$KEYBOARD_INPUT" in
    se|sv|swedish)
        KEYBOARD_LAYOUT="se"
        CONSOLE_KEYMAP="sv-latin1"
        ;;
    us|en)
        KEYBOARD_LAYOUT="us"
        CONSOLE_KEYMAP="us"
        ;;
    uk)
        KEYBOARD_LAYOUT="uk"
        CONSOLE_KEYMAP="uk"
        ;;
    de|german)
        KEYBOARD_LAYOUT="de"
        CONSOLE_KEYMAP="de-latin1"
        ;;
    fr|french)
        KEYBOARD_LAYOUT="fr"
        CONSOLE_KEYMAP="fr-latin1"
        ;;
    es|spanish)
        KEYBOARD_LAYOUT="es"
        CONSOLE_KEYMAP="es"
        ;;
    no|norwegian)
        KEYBOARD_LAYOUT="no"
        CONSOLE_KEYMAP="no-latin1"
        ;;
    dk|danish)
        KEYBOARD_LAYOUT="dk"
        CONSOLE_KEYMAP="dk-latin1"
        ;;
    fi|finnish)
        KEYBOARD_LAYOUT="fi"
        CONSOLE_KEYMAP="fi"
        ;;
    *)
        # Use as-is for other layouts (same for both)
        KEYBOARD_LAYOUT="$KEYBOARD_INPUT"
        CONSOLE_KEYMAP="$KEYBOARD_INPUT"
        ;;
esac

echo -e "${GREEN}→ Keyboard: ${KEYBOARD_LAYOUT} (graphical), ${CONSOLE_KEYMAP} (console)${NC}\n"

DEFAULT_LOCALE=$(prompt "Default locale" "en_US.UTF-8")
EXTRA_LOCALE=$(prompt "Extra locale (press Enter to skip, or enter locale like sv_SE.UTF-8)" "" "true")

echo ""
echo -e "${MAGENTA}=== Git Configuration ===${NC}\n"

GIT_USERNAME=$(prompt "Git username" "$(git config --global user.name 2>/dev/null || echo '')")
GIT_EMAIL=$(prompt "Git email" "$(git config --global user.email 2>/dev/null || echo '')")

echo ""
echo -e "${MAGENTA}=== Theme Selection ===${NC}\n"

echo "Available themes:"
echo "  1) catppuccin (default - dark theme)"
echo "  2) nixy (custom theme)"
echo ""

THEME_CHOICE=$(prompt "Select theme [1-2]" "1")

case "$THEME_CHOICE" in
    1) THEME="catppuccin" ;;
    2) THEME="nixy" ;;
    *) THEME="catppuccin" ;;
esac

echo ""
echo -e "${MAGENTA}=== System Options ===${NC}\n"

if confirm "Enable automatic system upgrades?" "n"; then
    AUTO_UPGRADE="true"
else
    AUTO_UPGRADE="false"
fi

if confirm "Enable automatic garbage collection?" "y"; then
    AUTO_GC="true"
else
    AUTO_GC="false"
fi

# Ask about optional modules
echo ""
echo -e "${MAGENTA}=== Optional Modules ===${NC}\n"

ENABLE_NVIDIA=false
ENABLE_DOCKER=false
ENABLE_TAILSCALE=false
ENABLE_BLUETOOTH=false

if confirm "Do you have an NVIDIA GPU?" "n"; then
    ENABLE_NVIDIA=true
fi

if confirm "Enable Docker?" "n"; then
    ENABLE_DOCKER=true
fi

if confirm "Enable Tailscale VPN?" "n"; then
    ENABLE_TAILSCALE=true
fi

if confirm "Enable Bluetooth?" "y"; then
    ENABLE_BLUETOOTH=true
fi

# Summary
echo ""
echo -e "${MAGENTA}=== Configuration Summary ===${NC}\n"
echo -e "${CYAN}Hostname:${NC}        ${YELLOW}${HOSTNAME}${NC}"
echo -e "${CYAN}Username:${NC}        ${YELLOW}${USERNAME}${NC}"
echo -e "${CYAN}Timezone:${NC}        ${YELLOW}${TIMEZONE}${NC}"
echo -e "${CYAN}Location:${NC}        ${YELLOW}${LOCATION}${NC}"
echo -e "${CYAN}Keyboard:${NC}        ${YELLOW}${KEYBOARD_LAYOUT}${NC} (graphical), ${YELLOW}${CONSOLE_KEYMAP}${NC} (console)"
echo -e "${CYAN}Default Locale:${NC}  ${YELLOW}${DEFAULT_LOCALE}${NC}"
[[ -n "$EXTRA_LOCALE" ]] && echo -e "${CYAN}Extra Locale:${NC}    ${YELLOW}${EXTRA_LOCALE}${NC}"
echo -e "${CYAN}Git Username:${NC}    ${YELLOW}${GIT_USERNAME}${NC}"
echo -e "${CYAN}Git Email:${NC}       ${YELLOW}${GIT_EMAIL}${NC}"
echo -e "${CYAN}Theme:${NC}           ${YELLOW}${THEME}${NC}"
echo -e "${CYAN}Auto Upgrade:${NC}    ${YELLOW}${AUTO_UPGRADE}${NC}"
echo -e "${CYAN}Auto GC:${NC}         ${YELLOW}${AUTO_GC}${NC}"
echo ""
echo -e "${CYAN}Optional Modules:${NC}"
echo -e "  NVIDIA:         ${YELLOW}${ENABLE_NVIDIA}${NC}"
echo -e "  Docker:         ${YELLOW}${ENABLE_DOCKER}${NC}"
echo -e "  Tailscale:      ${YELLOW}${ENABLE_TAILSCALE}${NC}"
echo -e "  Bluetooth:      ${YELLOW}${ENABLE_BLUETOOTH}${NC}"
echo ""

if ! confirm "Proceed with installation?" "y"; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 0
fi

# Start installation
echo ""
echo -e "${GREEN}=== Starting Installation ===${NC}\n"

# Check if host already exists
OVERWRITE_MODE=false
if [[ -d "${SCRIPT_DIR}/hosts/${HOSTNAME}" ]]; then
    echo -e "${YELLOW}Warning: Host '${HOSTNAME}' already exists!${NC}"
    if ! confirm "Overwrite existing host configuration?" "n"; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
    OVERWRITE_MODE=true
    rm -rf "${SCRIPT_DIR}/hosts/${HOSTNAME}"
fi

# Create host directory from template
echo -e "${BLUE}→ Creating host configuration from template...${NC}"
cp -r "${SCRIPT_DIR}/hosts/nihilix" "${SCRIPT_DIR}/hosts/${HOSTNAME}"
echo -e "${GREEN}✓ Host directory created${NC}\n"

# Generate and copy hardware configuration
echo -e "${BLUE}→ Generating hardware configuration...${NC}"
if sudo nixos-generate-config --show-hardware-config > "${SCRIPT_DIR}/hosts/${HOSTNAME}/hardware-configuration.nix"; then
    echo -e "${GREEN}✓ Hardware configuration generated${NC}\n"
else
    echo -e "${RED}✗ Failed to generate hardware configuration${NC}"
    exit 1
fi

# Create variables.nix
echo -e "${BLUE}→ Creating variables.nix...${NC}"

cat > "${SCRIPT_DIR}/hosts/${HOSTNAME}/variables.nix" << EOF
{
  config,
  lib,
  ...
}: {
  imports = [
    # Choose your theme here:
    ../../themes/${THEME}.nix
  ];

  config.var = {
    hostname = "${HOSTNAME}";
    username = "${USERNAME}";
    configDirectory = "${SCRIPT_DIR}"; # The path of the nixos configuration directory

    keyboardLayout = "${KEYBOARD_LAYOUT}";
    consoleKeyMap = "${CONSOLE_KEYMAP}";

    location = "${LOCATION}";
    timeZone = "${TIMEZONE}";
    defaultLocale = "${DEFAULT_LOCALE}";
EOF

if [[ -n "$EXTRA_LOCALE" ]]; then
    cat >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/variables.nix" << EOF
    extraLocale = "${EXTRA_LOCALE}";
EOF
else
    cat >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/variables.nix" << EOF
    extraLocale = "${DEFAULT_LOCALE}";
EOF
fi

cat >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/variables.nix" << EOF

    git = {
      username = "${GIT_USERNAME}";
      email = "${GIT_EMAIL}";
    };

    autoUpgrade = ${AUTO_UPGRADE};
    autoGarbageCollector = ${AUTO_GC};
  };

  # Let this here
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };
}
EOF

echo -e "${GREEN}✓ variables.nix created${NC}\n"

# Update configuration.nix with optional modules
echo -e "${BLUE}→ Configuring system modules...${NC}"

cat > "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix" << EOF
{config, ...}: {
  imports = [
    # Mostly system related configuration
    ../../nixos/audio.nix
EOF

if [[ "$ENABLE_BLUETOOTH" == "true" ]]; then
    echo "    ../../nixos/bluetooth.nix" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
else
    echo "    # ../../nixos/bluetooth.nix  # Disabled" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
fi

if [[ "$ENABLE_NVIDIA" == "true" ]]; then
    echo "    ../../nixos/nvidia.nix" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
else
    echo "    # ../../nixos/nvidia.nix  # Disabled - no NVIDIA GPU" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
fi

if [[ "$ENABLE_DOCKER" == "true" ]]; then
    echo "    ../../nixos/docker.nix" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
else
    echo "    # ../../nixos/docker.nix  # Disabled" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
fi

if [[ "$ENABLE_TAILSCALE" == "true" ]]; then
    echo "    ../../nixos/tailscale.nix" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
else
    echo "    # ../../nixos/tailscale.nix  # Disabled" >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix"
fi

cat >> "${SCRIPT_DIR}/hosts/${HOSTNAME}/configuration.nix" << EOF
    ../../nixos/fonts.nix
    ../../nixos/home-manager.nix
    ../../nixos/nix.nix
    ../../nixos/systemd-boot.nix
    ../../nixos/sddm.nix
    ../../nixos/users.nix
    ../../nixos/utils.nix
    ../../nixos/hyprland.nix

    # You should let those lines as is
    ./hardware-configuration.nix
    ./variables.nix
  ];

  home-manager.users."\${config.var.username}" = import ./home.nix;

  # Don't touch this
  system.stateVersion = "24.05";
}
EOF

echo -e "${GREEN}✓ configuration.nix created${NC}\n"

# Copy home.nix from template
echo -e "${BLUE}→ Copying home.nix from template...${NC}"
cp "${SCRIPT_DIR}/hosts/nihilix/home.nix" "${SCRIPT_DIR}/hosts/${HOSTNAME}/home.nix"
echo -e "${GREEN}✓ home.nix copied${NC}\n"

# Update flake.nix to register the new host
echo -e "${BLUE}→ Registering host in flake.nix...${NC}"

# Check if host already exists in flake.nix
FLAKE_HAS_HOST=false
if grep -q "${HOSTNAME} = nixpkgs.lib.nixosSystem" "${SCRIPT_DIR}/flake.nix" 2>/dev/null; then
    FLAKE_HAS_HOST=true
fi

# Skip only if host exists AND we're not in overwrite mode
if [[ "$FLAKE_HAS_HOST" == "true" ]] && [[ "$OVERWRITE_MODE" == "false" ]]; then
    echo -e "${YELLOW}Host '${HOSTNAME}' already exists in flake.nix, skipping...${NC}\n"
else
    # If we're overwriting and host exists in flake, we need to regenerate the entire flake.nix
    # Create temporary file with the new host entry
    cat > "${SCRIPT_DIR}/flake.nix.tmp" << 'FLAKE_EOF'
{
  # https://github.com/anotherhadi/nixy
  description = ''
    Nixy simplifies and unifies the Hyprland ecosystem with a modular, easily customizable setup.
    It provides a structured way to manage your system configuration and dotfiles with minimal effort.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    nixcord.url = "github:kaylorben/nixcord";
    sops-nix.url = "github:Mic92/sops-nix";
    nixarr.url = "github:rasmus-kirk/nixarr";
    nvf.url = "github:notashelf/nvf";
    vicinae.url = "github:vicinaehq/vicinae";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    eleakxir.url = "github:anotherhadi/eleakxir";
  };

  outputs = inputs @ {nixpkgs, ...}: {
    nixosConfigurations = {
FLAKE_EOF

    # Add all existing hosts from the original flake.nix (except the one we're replacing)
    # Extract existing host configurations (everything between nixosConfigurations = { and the closing };)
    awk -v hostname="${HOSTNAME}" '
        /nixosConfigurations = \{/ { in_configs=1; next }
        in_configs && /^    };$/ { exit }
        in_configs {
            # Check if this line starts a host definition
            if ($0 ~ /^      [a-zA-Z0-9_-]+ = nixpkgs\.lib\.nixosSystem/) {
                # Extract hostname from the line
                match($0, /^      ([a-zA-Z0-9_-]+) =/, arr)
                current_host = arr[1]
                # Skip this host if it matches the one we are replacing
                if (current_host == hostname) {
                    skip_host = 1
                    next
                }
            }
            # If we are at the closing brace of a host definition, reset skip flag
            if ($0 ~ /^      };$/) {
                if (skip_host) {
                    skip_host = 0
                    next
                }
            }
            # Print the line if we are not skipping this host
            if (!skip_host) {
                print
            }
        }
    ' "${SCRIPT_DIR}/flake.nix" >> "${SCRIPT_DIR}/flake.nix.tmp"

    # Add the new host entry
    cat >> "${SCRIPT_DIR}/flake.nix.tmp" << FLAKE_EOF
      ${HOSTNAME} = nixpkgs.lib.nixosSystem {
        modules = [
          {
            nixpkgs.overlays = [];
            _module.args = {
              inherit inputs;
            };
          }
FLAKE_EOF

    # Add nixos-hardware if NVIDIA is enabled
    if [[ "$ENABLE_NVIDIA" == "true" ]]; then
        cat >> "${SCRIPT_DIR}/flake.nix.tmp" << 'FLAKE_EOF'
          # inputs.nixos-hardware.nixosModules.YOUR-HARDWARE-MODULE  # Optional: add your specific hardware module
FLAKE_EOF
    fi

    cat >> "${SCRIPT_DIR}/flake.nix.tmp" << FLAKE_EOF
          inputs.home-manager.nixosModules.home-manager
          inputs.stylix.nixosModules.stylix
          ./hosts/${HOSTNAME}/configuration.nix
        ];
      };
    };
  };
}
FLAKE_EOF

    # Replace the old flake.nix with the new one
    mv "${SCRIPT_DIR}/flake.nix.tmp" "${SCRIPT_DIR}/flake.nix"
    echo -e "${GREEN}✓ Host registered in flake.nix${NC}\n"
fi

# Add everything to git
echo -e "${BLUE}→ Adding files to git...${NC}"
cd "${SCRIPT_DIR}"
git add .
echo -e "${GREEN}✓ Files added to git${NC}\n"

# Ask if user wants to rebuild now
echo ""
echo -e "${MAGENTA}=== Ready to Build ===${NC}\n"
echo -e "${YELLOW}The configuration is ready. Building will:${NC}"
echo -e "  • Enable flakes (automatically via nixos/nix.nix)"
echo -e "  • Download and install Hyprland and all applications"
echo -e "  • Configure your system with the settings you provided"
echo ""
echo -e "${YELLOW}This may take 20-40 minutes on first build.${NC}"
echo ""

if confirm "Build and apply configuration now?" "y"; then
    echo ""
    echo -e "${GREEN}=== Building System ===${NC}\n"
    echo -e "${BLUE}→ Running: sudo nixos-rebuild switch --flake ${SCRIPT_DIR}#${HOSTNAME}${NC}\n"

    if sudo nixos-rebuild switch --flake "${SCRIPT_DIR}#${HOSTNAME}"; then
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                          ║${NC}"
        echo -e "${GREEN}║   ✓ Installation Successful!             ║${NC}"
        echo -e "${GREEN}║                                          ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Your Nihilix system is ready!${NC}"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo -e "  1. Reboot your system: ${CYAN}reboot${NC}"
        echo -e "  2. Login at the SDDM screen"
        echo -e "  3. Enjoy your Hyprland environment!"
        echo ""
        echo -e "${YELLOW}Useful commands:${NC}"
        echo -e "  • ${CYAN}nixy${NC} - Interactive system management"
        echo -e "  • ${CYAN}SUPER + SPACE${NC} - Application launcher"
        echo -e "  • ${CYAN}SUPER + RETURN${NC} - Terminal"
        echo ""

        if confirm "Reboot now?" "n"; then
            echo -e "${GREEN}Rebooting...${NC}"
            sudo reboot
        fi
    else
        echo ""
        echo -e "${RED}✗ Build failed!${NC}"
        echo -e "${YELLOW}Check the error messages above and try again.${NC}"
        echo -e "${YELLOW}You can manually rebuild with:${NC}"
        echo -e "  ${CYAN}sudo nixos-rebuild switch --flake ${SCRIPT_DIR}#${HOSTNAME}${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}Configuration created but not built.${NC}"
    echo -e "${YELLOW}To build later, run:${NC}"
    echo -e "  ${CYAN}sudo nixos-rebuild switch --flake ${SCRIPT_DIR}#${HOSTNAME}${NC}"
    echo ""
fi

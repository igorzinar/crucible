#!/bin/bash

# Print the logo
print_logo() {
    cat << "EOF"
    ______                _ __    __     
   / ____/______  _______(_) /_  / /__   
  / /   / ___/ / / / ___/ / __ \/ / _ \  
 / /___/ /  / /_/ / /__/ / /_/ / /  __/  Arch Linux System Crafting Tool
 \____/_/   \__,_/\___/_/_.___/_/\___/   by: typecraft

EOF
}

# Parse command line arguments
DEV_ONLY=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dev-only) DEV_ONLY=true; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
done

# Clear screen and show logo
clear
print_logo

# Exit on any error
set -e

# Source utility functions
source utils.sh

# Source the package list
if [ ! -f "packages.conf" ]; then
  echo "Error: packages.conf not found!"
  exit 1
fi

source packages.conf

if [[ "$DEV_ONLY" == true ]]; then
  echo "Starting development-only setup..."
else
  echo "Starting full system setup..."
fi

# Update the system first
echo "Updating system..."
sudo pacman -Syu --noconfirm
# Install paru AUR helper if not present
if ! command -v paru &> /dev/null; then # Changed 'yay' to 'paru'
  echo "Installing paru AUR helper..." # Changed 'yay' to 'paru'
  sudo pacman -S --needed git base-devel --noconfirm

  # Changed directory name from 'yay' to 'paru_build' for clarity and to avoid conflicts
  if [[ ! -d "/tmp/paru_build" ]]; then
    echo "Cloning paru repository..." # Changed 'yay' to 'paru'
  else
    echo "paru build directory already exists, removing it..." # Changed 'yay' to 'paru'
    rm -rf /tmp/paru_build # Changed directory name
  fi

  # Changed repository URL to paru's AUR repo
  git clone https://aur.archlinux.org/paru.git /tmp/paru_build

  cd /tmp/paru_build # Changed directory name
  echo "building paru...." # Changed 'yay' to 'paru'
  makepkg -si --noconfirm

  cd "${CRUCIBLE_DIR}" # Ensure we return to the script's original directory (assuming CRUCIBLE_DIR is defined)
  rm -rf /tmp/paru_build # Changed directory name
else
  echo "paru is already installed" # Changed 'yay' to 'paru'
fi

# Install packages by category
if [[ "$DEV_ONLY" == true ]]; then
  # Only install essential development packages
  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"
  
  echo "Installing development tools..."
  install_packages "${DEV_TOOLS[@]}"
else
  # Install all packages
  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"
  
  echo "Installing development tools..."
  install_packages "${DEV_TOOLS[@]}"
  
  echo "Installing system maintenance tools..."
  install_packages "${MAINTENANCE[@]}"
  
  echo "Installing desktop environment..."
  install_packages "${DESKTOP[@]}"
  
  echo "Installing desktop environment..."
  install_packages "${OFFICE[@]}"
  
  echo "Installing media packages..."
  install_packages "${MEDIA[@]}"
  
  echo "Installing fonts..."
  install_packages "${FONTS[@]}"
  
  # Enable services
  echo "Configuring services..."
  for service in "${SERVICES[@]}"; do
    if ! systemctl is-enabled "$service" &> /dev/null; then
      echo "Enabling $service..."
      sudo systemctl enable "$service"
    else
      echo "$service is already enabled"
    fi
  done
  
#  # Install gnome specific things to make it like a tiling WM
#  echo "Installing Gnome extensions..."
#  . gnome/gnome-extensions.sh
#  echo "Setting Gnome hotkeys..."
#  . gnome/gnome-hotkeys.sh
#  echo "Configuring Gnome..."
#  . gnome/gnome-settings.sh
#
  # Some programs just run better as flatpaks. Like discord/spotify
  echo "Installing flatpaks (like discord and spotify)"
  . install-flatpaks.sh
fi

echo "Setup complete! You may want to reboot your system."

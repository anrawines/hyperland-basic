#!/bin/bash
set -e  # Exit on error

echo "================================"
echo "Installing Hyprland Dotfiles"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Install base packages
echo "Installing base-devel and git..."
sudo pacman -S --needed --noconfirm base-devel git

# Check for AUR helper
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd -
fi
AUR_HELPER=$(command -v yay || command -v paru)

# Backup existing configs
BACKUP_DIR=~/dotfiles_backup_$(date +%Y%m%d_%H%M%S)
echo "Backing up existing configs to $BACKUP_DIR"
mkdir -p $BACKUP_DIR
[ -d ~/.config ] && cp -r ~/.config $BACKUP_DIR/

# Install Hyprland & Wayland Essentials
echo "Installing system packages..."
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock hypridle hyprpaper \
    waybar rofi dunst kitty \
    brightnessctl libpulse playerctl pavucontrol blueman \
    grim slurp wl-clipboard \
	xdg-desktop-portal-hyprland \
	jq socat \
    polkit-gnome \
    
# Install SDDM and a minimal theme
echo "Setting up SDDM..."
sudo pacman -S --needed --noconfirm sddm

# Download a minimal dark theme (Sugar Candy)
$AUR_HELPER -S --needed --noconfirm sddm-theme-sugar-candy-git

# Create the SDDM config file to use the theme
sudo mkdir -p /etc/sddm.conf.d
echo "[Theme]
Current=sugar-candy" | sudo tee /etc/sddm.conf.d/theme.conf

# Enable the service
sudo systemctl enable sddm
success "SDDM enabled with Sugar Candy theme"

# Install Fonts
echo "Installing fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    noto-fonts-emoji \
    otf-font-awesome

# Install AUR packages
echo "Installing AUR packages..."
$AUR_HELPER -S --needed --noconfirm \
    matugen-bin \
    swww \
    hyprpicker-git

# Create necessary Wayland directories
echo "Creating directories..."
mkdir -p ~/.config/{hypr,waybar,rofi,dunst,kitty,m3-colors}
mkdir -p ~/.local/{share,bin}
mkdir -p ~/Pictures/Wallpapers

# Copy dotfiles
echo "Copying dotfiles..."
if [ -d ".config" ]; then
    rsync -av --exclude='*.tmp' .config/ ~/.config/
    success ".config copied"
fi

# Copy scripts
if [ -d ".local/bin" ]; then
    rsync -av .local/bin/ ~/.local/bin/
    chmod +x ~/.local/bin/* 2>/dev/null || true
    success "Scripts copied"
fi

# Copy wallpapers
if [ -d "wallpapers" ] || [ -d "Wallpapers" ]; then
    cp -r wallpapers/* ~/Pictures/Wallpapers/ 2>/dev/null || cp -r Wallpapers/* ~/Pictures/Wallpapers/ 2>/dev/null
    success "Wallpapers copied"
fi

# Initialize Theme and Colors
echo "================================"
echo "Generating Colors with Matugen..."
echo "================================"

# Find the wallpaper defined in your hyprpaper.conf
WALLPAPER=~/Pictures/Wallpapers/night.jpg

if [ -f "$WALLPAPER" ]; then
    echo "Applying theme based on: $WALLPAPER"
    matugen image "$WALLPAPER"
    success "Matugen colors generated"
else
    warning "Default wallpaper not found at $WALLPAPER, skipping Matugen"
fi

echo ""
echo "================================"
echo "Installation Complete!"
echo "================================"
echo "Next steps:"
echo "   If you use NVIDIA, ensure 'nvidia_drm.modeset=1' is in your kernel parameters."
echo ""
echo "================================"

#!/bin/sh
# Installs ccjail to ~/.local/bin
set -e

REPO_URL="https://raw.githubusercontent.com/artilugio0/ccjail/main"
INSTALL_DIR="${HOME}/.local/bin"
TEMPLATES_DIR="${HOME}/.local/share/ccjail/templates"

echo "Installing ccjail..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMPLATES_DIR"

curl -fsSL "$REPO_URL/ccjail.sh" -o "$INSTALL_DIR/ccjail"
chmod +x "$INSTALL_DIR/ccjail"

curl -fsSL "$REPO_URL/templates/Dockerfile" -o "$TEMPLATES_DIR/Dockerfile"

# Patch the SCRIPT_DIR in the installed script to point to the templates location
sed -i.bak "s|SCRIPT_DIR=\"\$(cd \"\$(dirname \"\$0\")\" && pwd)\"|SCRIPT_DIR=\"${HOME}/.local/share/ccjail\"|" "$INSTALL_DIR/ccjail"
rm -f "$INSTALL_DIR/ccjail.bak"

echo "Installed ccjail to $INSTALL_DIR/ccjail"
echo "Templates installed to $TEMPLATES_DIR"
echo ""

# Check if INSTALL_DIR is on PATH
case ":$PATH:" in
    *":$INSTALL_DIR:"*)
        echo "ccjail is ready. Try: ccjail help"
        ;;
    *)
        echo "NOTE: Add $INSTALL_DIR to your PATH to use ccjail:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "  # or for zsh:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
        ;;
esac

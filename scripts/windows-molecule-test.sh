#!/bin/bash
# Windows Molecule Test Helper
# Automatically detects architecture and uses QEMU (preferred) or fallback providers
# 
# Usage:
#   ./scripts/windows-molecule-test.sh [role_path] [action]
#   ./scripts/windows-molecule-test.sh roles/windows/iis test
#   ./scripts/windows-molecule-test.sh roles/windows/iis converge

set -e

ROLE_DIR="${1:-.}"
ACTION="${2:-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=============================================="
echo "  Windows Molecule Test Helper"
echo "=============================================="

# Detect system info
ARCH=$(uname -m)
OS=$(uname -s)
CHIP_GEN=""

# Detect Apple Silicon variant
if [[ "$OS" == "Darwin" && "$ARCH" == "arm64" ]]; then
    CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Apple Silicon")
    if echo "$CHIP" | grep -qE "M[1-4]"; then
        CHIP_GEN=$(echo "$CHIP" | grep -oE "M[1-4]( Pro| Max| Ultra)?" | head -1)
    else
        CHIP_GEN="Apple Silicon"
    fi
elif [[ "$OS" == "Darwin" ]]; then
    CHIP_GEN="Intel Mac"
elif [[ "$OS" == "Linux" ]]; then
    CHIP_GEN="Linux"
fi

log_info "System: $OS ($ARCH)"
[[ -n "$CHIP_GEN" ]] && log_info "Chip: $CHIP_GEN"
log_info "Role: $ROLE_DIR"
log_info "Action: $ACTION"
echo ""

# Check providers and select best one
log_info "Checking providers..."

# Check delegated
DELEGATED_STATUS="not-configured"
if [[ -n "$WINDOWS_HOST" && -n "$WINDOWS_PASSWORD" ]]; then
    DELEGATED_STATUS="ready"
fi
echo "  Delegated (remote host): $DELEGATED_STATUS"

# Check QEMU
QEMU_STATUS="not-installed"
if command -v qemu-system-x86_64 &>/dev/null; then
    if vagrant plugin list 2>/dev/null | grep -q vagrant-qemu; then
        QEMU_STATUS="ready"
    else
        QEMU_STATUS="no-plugin"
    fi
fi
echo "  QEMU: $QEMU_STATUS"

# Check VirtualBox
VBOX_STATUS="not-installed"
if command -v VBoxManage &>/dev/null; then
    VBOX_STATUS="ready"
fi
echo "  VirtualBox: $VBOX_STATUS"
echo ""

# Select provider (priority: delegated > qemu > virtualbox)
PROVIDER=""
SCENARIO=""

if [[ "$DELEGATED_STATUS" == "ready" ]]; then
    PROVIDER="delegated"
    SCENARIO="delegated"
elif [[ "$QEMU_STATUS" == "ready" ]]; then
    PROVIDER="qemu"
    SCENARIO="qemu"
    export VAGRANT_DEFAULT_PROVIDER=qemu
elif [[ "$ARCH" == "x86_64" && "$VBOX_STATUS" == "ready" ]]; then
    PROVIDER="virtualbox"
    SCENARIO="default"
    export VAGRANT_DEFAULT_PROVIDER=virtualbox
elif [[ "$QEMU_STATUS" == "no-plugin" ]]; then
    log_warn "QEMU found but vagrant-qemu plugin is missing!"
    echo ""
    echo "  Install the plugin:"
    echo "    vagrant plugin install vagrant-qemu"
    echo ""
    exit 1
else
    log_error "No Windows VM provider found!"
    echo ""
    echo "Recommended: Install QEMU (works on macOS and Linux, ARM and x86)"
    echo ""
    if [[ "$OS" == "Darwin" ]]; then
        echo "  brew install qemu"
        echo "  vagrant plugin install vagrant-qemu"
    elif [[ "$OS" == "Linux" ]]; then
        echo "  # Ubuntu/Debian:"
        echo "  sudo apt-get install qemu-system-x86 qemu-utils"
        echo "  vagrant plugin install vagrant-qemu"
        echo ""
        echo "  # RHEL/CentOS/Fedora:"
        echo "  sudo dnf install qemu-kvm qemu-img"
        echo "  vagrant plugin install vagrant-qemu"
    fi
    echo ""
    echo "Alternative: Use a remote Windows host"
    echo "  export WINDOWS_HOST=<ip-address>"
    echo "  export WINDOWS_USER=Administrator"
    echo "  export WINDOWS_PASSWORD=<password>"
    echo "  molecule test -s delegated"
    echo ""
    exit 1
fi

log_success "Selected provider: $PROVIDER"
log_success "Using scenario: $SCENARIO"
[[ -n "$VAGRANT_DEFAULT_PROVIDER" ]] && log_info "VAGRANT_DEFAULT_PROVIDER=$VAGRANT_DEFAULT_PROVIDER"
echo ""

# Check if scenario exists
if [[ ! -d "$ROLE_DIR/molecule/$SCENARIO" ]]; then
    log_error "Scenario '$SCENARIO' not found in $ROLE_DIR/molecule/"
    log_info "Available scenarios:"
    ls -1 "$ROLE_DIR/molecule/" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
    exit 1
fi

# Critical warning for QEMU on ARM with Windows Server
if [[ "$PROVIDER" == "qemu" && "$ARCH" == "arm64" ]]; then
    echo ""
    log_warn "=============================================="
    log_warn "IMPORTANT: Windows Server ARM Limitation"
    log_warn "=============================================="
    echo ""
    echo "  Windows Server does NOT support ARM architecture."
    echo "  Microsoft only provides x86_64 (x64) Windows Server images."
    echo ""
    echo "  QEMU will emulate x86_64 on your ARM Mac, but this is"
    echo "  EXTREMELY SLOW (expect 30-60+ minutes for full test)."
    echo ""
    echo "  RECOMMENDED ALTERNATIVES:"
    echo "    1. Use 'delegated' scenario with a remote Windows host:"
    echo "       export WINDOWS_HOST=<ip-address>"
    echo "       export WINDOWS_USER=Administrator"
    echo "       export WINDOWS_PASSWORD=<password>"
    echo "       molecule test -s delegated"
    echo ""
    echo "    2. Use a cloud Windows VM (Azure, AWS, GCP)"
    echo ""
    echo "    3. Use Parallels/UTM with Windows 11 (consumer, not Server)"
    echo ""
    echo "  See docs/windows-testing.md for detailed instructions."
    echo ""
    read -p "  Continue with slow QEMU emulation? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted. Use 'molecule test -s delegated' with a Windows host."
        exit 0
    fi
    echo ""
fi

echo "=============================================="
log_info "Running: molecule $ACTION -s $SCENARIO"
echo "=============================================="
echo ""

cd "$ROLE_DIR"
exec molecule "$ACTION" -s "$SCENARIO"

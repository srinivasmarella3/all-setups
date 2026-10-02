cat > /root/install-kubectl-kops.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Installing required packages..."
apt-get update
apt-get install -y curl ca-certificates

ARCH="$(uname -m)"

case "$ARCH" in
  x86_64|amd64)
    BINARY_ARCH="amd64"
    ;;
  aarch64|arm64)
    BINARY_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "Detected architecture: $BINARY_ARCH"

echo "Installing kubectl..."
KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BINARY_ARCH}/kubectl"
KUBECTL_SHA_URL="${KUBECTL_URL}.sha256"

echo "kubectl version: $KUBECTL_VERSION"
echo "kubectl URL: $KUBECTL_URL"

curl -fL "$KUBECTL_URL" -o /tmp/kubectl
curl -fL "$KUBECTL_SHA_URL" -o /tmp/kubectl.sha256

echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check

install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl

echo "Installing kOps..."
KOPS_VERSION="$(curl -fsSL https://api.github.com/repos/kubernetes/kops/releases/latest \
  | grep '"tag_name"' \
  | head -n 1 \
  | cut -d '"' -f 4)"

if [ -z "$KOPS_VERSION" ]; then
  echo "Unable to determine the latest kOps version."
  exit 1
fi

KOPS_URL="https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-${BINARY_ARCH}"

echo "kOps version: $KOPS_VERSION"
echo "kOps URL: $KOPS_URL"

curl -fL "$KOPS_URL" -o /tmp/kops
install -o root -g root -m 0755 /tmp/kops /usr/local/bin/kops

echo "Refreshing shell command cache..."
hash -r

echo
echo "Installed files:"
ls -lh /usr/local/bin/kubectl
ls -lh /usr/local/bin/kops

echo
echo "kubectl version:"
/usr/local/bin/kubectl version --client

echo
echo "kOps version:"
/usr/local/bin/kops version

echo
echo "Installation completed successfully."
EOF

chmod +x /root/install-kubectl-kops.sh

bash -x /root/install-kubectl-kops.sh

sudo apt update
sudo apt install -y unzip curl
curl -fsSL 'https://awscli.amazonaws.com/v2/install.sh' | sudo bash -s -- --system

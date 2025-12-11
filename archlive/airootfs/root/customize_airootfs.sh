#!/usr/bin/env bash
set -e

echo "[customize_airootfs] start"

# Hostname
echo "NeuronOS" > /etc/hostname


# Enable services by creating enablement symlinks (safe inside chroot)
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager.service /etc/systemd/system/multi-user.target.wants/NetworkManager.service || true
ln -sf /usr/lib/systemd/system/docker.service /etc/systemd/system/multi-user.target.wants/docker.service || true
ln -sf /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service || true

# Create the capstone user (if not already present)
if ! id -u capstone >/dev/null 2>&1; then
  useradd -m -G wheel -s /usr/bin/zsh capstone || true
  echo "capstone:password" | chpasswd || true
fi

# Ensure sudoers allows wheel (uncomment wheel line)
sed -i 's/^# %wheel/%wheel/' /etc/sudoers || true

# Make zsh the default shell for capstone (ignore failures)
chsh -s /usr/bin/zsh capstone || true

# Ensure installer exists and is executable. If you pre-copied it into the tree,
# this will just ensure permissions. If not present, this logs an error.
if [ -f /usr/local/bin/neuronos-installer ]; then
  chmod 755 /usr/local/bin/neuronos-installer || true
else
  echo "[customize_airootfs] WARNING: /usr/local/bin/neuronos-installer missing"
fi

# Create system-wide autostart .desktop that runs the installer via sh (avoids needing +x)

# Create per-user autostart script in the capstone home (this is the guaranteed fallback)
mkdir -p /home/capstone/.config/autostart-scripts
cp -f /usr/local/bin/neuronos-installer /home/capstone/.config/autostart-scripts/installer.sh || true
chown -R capstone:capstone /home/capstone/.config
chmod 755 /home/capstone/.config/autostart-scripts/installer.sh || true

# Also populate /etc/skel so any subsequently created user gets the same autostart script
mkdir -p /etc/skel/.config/autostart-scripts
cp -f /usr/local/bin/neuronos-installer /etc/skel/.config/autostart-scripts/installer.sh || true
chmod 755 /etc/skel/.config/autostart-scripts/installer.sh || true

# Setup SDDM autologin (keep as you had)
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<'EOF'
[Autologin]
User=capstone
Session=plasma.desktop
EOF

# Cleanup caches (non-interactively)
yes | pacman -Scc >/dev/null 2>&1 || true
rm -rf /root/.cache/pip /home/*/.cache/pip || true

echo "almos [customize_airootfs] done"
sleep 45

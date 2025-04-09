#!/bin/bash

# Dieses Skript erstellt ein angepasstes Debian Live-System mit GNOME und eigenem Hintergrundbild
# sowie einem benutzerdefinierten GRUB-Hintergrundbild und Dark Mode aktiviert

# Benötigte Pakete installieren
sudo apt-get update
sudo apt-get install -y live-build live-config live-boot curl

# Arbeitsverzeichnis erstellen
mkdir -p debian-live-custom
cd debian-live-custom

# Live-Build-Konfiguration initialisieren
lb config \
  --distribution bookworm \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer none \
  --debian-installer-gui false \
  --bootappend-live "boot=live components locales=de_DE.UTF-8 keyboard-layouts=de"

# Installationspakete für GNOME Desktop hinzufügen
mkdir -p config/package-lists/
cat > config/package-lists/desktop.list.chroot << EOF
gnome-core
gnome-shell
gnome-session
gnome-terminal
gnome-shell-extensions
gnome-tweaks
papirus-icon-theme
gdm3
firmware-linux
curl
grub2-common
grub-common
firefox-esr
tor
torbrowser-launcher
wireshark
nmap
aircrack-ng
git
curl
wget
EOF

# Eigenes Hintergrundbild vorbereiten für GNOME
mkdir -p config/includes.chroot/usr/share/backgrounds/custom
mkdir -p config/includes.chroot/etc/skel/.config/

# Hintergrundbild herunterladen
curl -o config/includes.chroot/usr/share/backgrounds/custom/hintergrundbild.jpg https://raw.githubusercontent.com/noKrypton/image/main/vendetta.jpg

# GNOME Dconf-Einstellungen für Dark Mode und Terminal-Einstellungen
mkdir -p config/includes.chroot/etc/skel/.config/dconf/
cat > config/includes.chroot/etc/skel/.config/dconf/user.d << EOF
# Dummy-Datei, wird durch den Hook erstellt
EOF

# Hook erstellen, um Dark Mode und Terminal-Einstellungen zu konfigurieren
mkdir -p config/hooks/live/
cat > config/hooks/live/0015-configure-dark-mode.hook.chroot << EOF
#!/bin/bash
# Dark Mode und andere GNOME-Einstellungen konfigurieren

# Erstelle das Verzeichnis für den Live-Benutzer
mkdir -p /etc/skel/.config/dconf/

# Erstelle eine dconf-Datenbank für die Standardeinstellungen
cat > /etc/skel/.config/dconf/user << EOF2
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Adwaita-dark'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/hintergrundbild.jpg'
picture-uri-dark='file:///usr/share/backgrounds/custom/hintergrundbild.jpg'

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
background-color='rgb(0,0,0)'
foreground-color='rgb(255,255,255)'
use-theme-colors=false
EOF2

# Stelle sicher, dass die Berechtigungen korrekt sind
chmod 644 /etc/skel/.config/dconf/user
EOF
chmod +x config/hooks/live/0015-configure-dark-mode.hook.chroot

# Skript erstellen, um Dark Mode nach dem Start zu setzen
mkdir -p config/includes.chroot/usr/local/bin/
cat > config/includes.chroot/usr/local/bin/set-dark-mode.sh << EOF
#!/bin/bash
# Dark Mode setzen
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/custom/hintergrundbild.jpg'

# Terminal-Einstellungen
profile=\$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ background-color 'rgb(0,0,0)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ foreground-color 'rgb(255,255,255)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ use-theme-colors false
EOF
chmod +x config/includes.chroot/usr/local/bin/set-dark-mode.sh

# Autostart-Eintrag erstellen
mkdir -p config/includes.chroot/etc/skel/.config/autostart/
cat > config/includes.chroot/etc/skel/.config/autostart/set-dark-mode.desktop << EOF
[Desktop Entry]
Type=Application
Name=Set Dark Mode
Exec=/usr/local/bin/set-dark-mode.sh
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# Wir erstellen auch einen Hook, um das Hintergrundbild während des Build-Prozesses herunterzuladen
mkdir -p config/hooks/live/
cat > config/hooks/live/0010-download-wallpaper.hook.chroot << EOF
#!/bin/bash
# Hintergrundbild nochmals herunterladen
curl -o /usr/share/backgrounds/custom/hintergrundbild.jpg https://raw.githubusercontent.com/noKrypton/image/main/vendetta.jpg
EOF
chmod +x config/hooks/live/0010-download-wallpaper.hook.chroot

# GDM-Konfiguration für automatischen Login
mkdir -p config/includes.chroot/etc/gdm3/
cat > config/includes.chroot/etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=v

[security]

[xdmcp]

[greeter]

[chooser]

[debug]
EOF

# Konfiguration für den Standard-Live-Benutzer
mkdir -p config/includes.chroot/etc/live/config/
cat > config/includes.chroot/etc/live/config/user-setup.conf << EOF
# Anpassungen für den Live-Benutzer
LIVE_USER_DEFAULT="v"
LIVE_USER_FULLNAME="V User"
EOF

# GRUB Hintergrundbild direkt herunterladen und in den richtigen Ordner legen
mkdir -p config/includes.binary/boot/grub/
curl -o config/includes.binary/boot/grub/grub-background.png https://raw.githubusercontent.com/noKrypton/image/main/grub.png

# Schriftarten für GRUB vorbereiten
mkdir -p config/includes.binary/boot/grub/fonts/

# Kopiere unicode.pf2 und erstelle einen Symlink auf font.pf2
cp /usr/share/grub/unicode.pf2 config/includes.binary/boot/grub/fonts/ || echo "Unicode font not found, using system default"
cp /usr/share/grub/unicode.pf2 config/includes.binary/boot/grub/font.pf2 || echo "Could not create font.pf2"

# GRUB-Menüeinträge anpassen - kombinierte Version aus beiden Ansätzen
mkdir -p config/includes.binary/boot/grub/
cat > config/includes.binary/boot/grub/grub.cfg << EOF
# GRUB-Konfiguration mit Hintergrundbild

# Zeitüberschreitung und Standard-Boot-Option
set default=0
set timeout=5

# Hintergrundbild laden
if loadfont /boot/grub/font.pf2 ; then
  set gfxmode=auto
  insmod efi_gop
  insmod efi_uga
  insmod gfxterm
  terminal_output gfxterm
fi

# Hintergrundbild setzen
insmod png
background_image /boot/grub/grub-background.png

# Menüfarben anpassen
set menu_color_normal=white/black
set menu_color_highlight=black/white

# Boot-Menüeinträge
menuentry "Debian Live" {
  linux /live/vmlinuz boot=live components quiet splash
  initrd /live/initrd.img
}

menuentry "Debian Live (failsafe)" {
  linux /live/vmlinuz boot=live components memtest noapic noapm nodma nomce nolapic nomodeset nosmp nosplash vga=788
  initrd /live/initrd.img
}
EOF

# Live-Build ausführen
lb build

echo "Debian Live ISO wurde erstellt. Die Datei befindet sich im aktuellen Verzeichnis."

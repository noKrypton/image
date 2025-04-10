#!/bin/bash

# Dieses Skript erstellt ein angepasstes Debian Live-System mit GNOME und eigenem Hintergrundbild
# sowie einem benutzerdefinierten GRUB-Hintergrundbild und Dark Mode aktiviert

# Benötigte Pakete installieren
sudo apt-get update
sudo apt-get install -y live-build live-config live-boot curl

# Arbeitsverzeichnis erstellen
mkdir -p debian-live-custom
cd debian-live-custom

# Altes Build-Verzeichnis säubern, falls vorhanden
sudo lb clean --all 2>/dev/null || true

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
gdm3
firmware-linux
curl
grub2-common
grub-common
tor
torbrowser-launcher
wireshark
nmap
aircrack-ng
git
curl
wget
gnome-shell-extensions
unzip
gnome-tweaks
dconf-cli
dconf-editor
EOF

# Verzeichnisstruktur für Hintergrundbilder erstellen
mkdir -p config/includes.chroot/usr/share/backgrounds/custom
mkdir -p config/includes.chroot/etc/skel/.config/
mkdir -p config/includes.binary/boot/grub/

# GRUB und Desktop Hintergrundbild herunterladen
# Lokale Kopie herunterladen und speichern
curl -o grub-background.png https://raw.githubusercontent.com/noKrypton/image/main/grub.png
cp grub-background.png config/includes.binary/boot/grub/grub-background.png
cp grub-background.png config/includes.chroot/usr/share/backgrounds/custom/desktop-background.png

# GNOME Dconf-Einstellungen-Verzeichnis erstellen
mkdir -p config/includes.chroot/etc/skel/.config/dconf/
mkdir -p config/includes.chroot/etc/skel/.config/autostart/

# Rotes Theme erstellen
mkdir -p config/includes.chroot/usr/share/themes/Red-Theme/gnome-shell/
cat > config/includes.chroot/usr/share/themes/Red-Theme/gnome-shell/gnome-shell.css << EOF
/* Red Theme for GNOME Shell */
stage {
    color: #ffffff;
}

.panel-button {
    color: #ffffff;
}

#panel {
    background-color: rgba(200, 0, 0, 0.8);
    color: #ffffff;
}

/* Titel-Leisten nicht transparent machen */
.window-frame {
    background-color: rgba(200, 0, 0, 1.0);
    border: none;
}

.header-bar {
    background-color: rgba(200, 0, 0, 1.0);
    border: none;
}

.titlebar {
    background-color: rgba(200, 0, 0, 1.0);
    border: none;
}

/* Dash-Anpassungen für das abgerundete Viereck */
.dash-background {
    background-color: rgba(200, 0, 0, 0.7);
    border: 1px solid rgba(255, 80, 80, 0.7);
    border-radius: 24px;
    margin-left: 15%;
    margin-right: 15%;
    margin-bottom: 10px;
}

.dash {
    margin-left: 15%;
    margin-right: 15%;
}

.app-well-app:hover .overview-icon,
.app-well-app:focus .overview-icon,
.app-well-app:selected .overview-icon {
    background-color: rgba(255, 100, 100, 0.5);
}

.search-entry {
    background-color: rgba(200, 0, 0, 0.3);
    border-color: rgba(255, 100, 100, 0.5);
    color: #ffffff;
}

/* Andere Elemente können hier angepasst werden */
EOF

# Stylesheet-Datei für das Theme erstellen
mkdir -p config/includes.chroot/usr/share/themes/Red-Theme/gtk-3.0/
cat > config/includes.chroot/usr/share/themes/Red-Theme/gtk-3.0/gtk.css << EOF
/* Red Theme for GTK 3.0 */
@import url("resource:///org/gnome/theme/Adwaita-dark.css");

/* Anpassungen für das rote Theme */
@define-color theme_selected_bg_color #CC0000;
@define-color theme_selected_fg_color #FFFFFF;

/* Titel-Leisten nicht transparent machen */
headerbar {
    background-color: @theme_selected_bg_color;
    border: none;
}

.titlebar {
    background-color: @theme_selected_bg_color;
    border: none;
}

window.solid-csd headerbar.titlebar {
    background-color: @theme_selected_bg_color;
    border: none;
}

window.ssd headerbar.titlebar {
    background-color: @theme_selected_bg_color;
    border: none;
}
EOF

# Theme Index-Datei hinzufügen
mkdir -p config/includes.chroot/usr/share/themes/Red-Theme/
cat > config/includes.chroot/usr/share/themes/Red-Theme/index.theme << EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Red-Theme
Comment=Red custom theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Red-Theme
MetacityTheme=Adwaita
IconTheme=Adwaita
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:
EOF

# Hook erstellen, um Dark Mode und Terminal-Einstellungen zu konfigurieren
mkdir -p config/hooks/live/
cat > config/hooks/live/0015-configure-dark-mode.hook.chroot << EOF
#!/bin/bash
# Dark Mode und andere GNOME-Einstellungen konfigurieren

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/dark-mode-setup.log 2>&1

# Erstelle das Verzeichnis für den Live-Benutzer
mkdir -p /etc/skel/.config/dconf/

# GNOME Systemweite Einstellungen
mkdir -p /etc/dconf/db/local.d/
mkdir -p /etc/dconf/profile/

# dconf-Profile konfigurieren
echo "user-db:user
system-db:local" > /etc/dconf/profile/user

# Erstelle eine dconf-Systemweite Datenbank für die Standardeinstellungen
cat > /etc/dconf/db/local.d/00-desktop << EOF2
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Red-Theme'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/desktop-background.png'
picture-uri-dark='file:///usr/share/backgrounds/custom/desktop-background.png'

[org/gnome/terminal/legacy/profiles:]
default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
background-color='rgb(0,0,0)'
foreground-color='rgb(255,255,255)'
use-theme-colors=false

[org/gnome/shell]
enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']

[org/gnome/shell/extensions/user-theme]
name='Red-Theme'

[org/gnome/shell/extensions/dash-to-dock]
dock-fixed=true
extend-height=false
transparency-mode='FIXED'
background-opacity=0.7
dash-max-icon-size=48
dock-position='BOTTOM'
preferred-monitor=0
custom-theme-shrink=true
height-fraction=0.5
require-pressure-to-show=false
pressure-threshold=0
intellihide=false
show-trash=false
show-mounts=false
show-apps-at-top=false
show-show-apps-button=true
multi-monitor=false
EOF2

# Für den Benutzer in einem Format, das dconf direkt verwenden kann
mkdir -p /etc/skel/.config/dconf/
cat > /etc/skel/.config/dconf/user.db << EOF2
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Red-Theme'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/desktop-background.png'
picture-uri-dark='file:///usr/share/backgrounds/custom/desktop-background.png'

[org/gnome/terminal/legacy/profiles:]
default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
background-color='rgb(0,0,0)'
foreground-color='rgb(255,255,255)'
use-theme-colors=false

[org/gnome/shell]
enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']

[org/gnome/shell/extensions/user-theme]
name='Red-Theme'

[org/gnome/shell/extensions/dash-to-dock]
dock-fixed=true
extend-height=false
transparency-mode='FIXED'
background-opacity=0.7
dash-max-icon-size=48
dock-position='BOTTOM'
preferred-monitor=0
custom-theme-shrink=true
height-fraction=0.5
require-pressure-to-show=false
pressure-threshold=0
intellihide=false
show-trash=false
show-mounts=false
show-apps-at-top=false
show-show-apps-button=true
multi-monitor=false
EOF2

# Hintergrundbild kopieren (redundant, aber sicherer)
cp /usr/share/backgrounds/custom/desktop-background.png /etc/skel/desktop-background.png

# Erstellen Sie ein Skript, das bei jedem Login ausgeführt wird
mkdir -p /etc/profile.d/
cat > /etc/profile.d/gnome-settings.sh << EOF2
#!/bin/bash
# Gnome-Einstellungen bei jedem Login anwenden
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Red-Theme'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/custom/desktop-background.png'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/custom/desktop-background.png'
EOF2
chmod +x /etc/profile.d/gnome-settings.sh

# Dconf-Datenbank aktualisieren
dconf update || echo "dconf update fehlgeschlagen"

# Stelle sicher, dass die Berechtigungen korrekt sind
chmod -R 755 /etc/skel/.config/
chmod 644 /etc/skel/.config/dconf/user.db

echo "Dark-Mode-Setup abgeschlossen" 
EOF
chmod +x config/hooks/live/0015-configure-dark-mode.hook.chroot

# GDM-Konfiguration für automatischen Login
mkdir -p config/includes.chroot/etc/gdm3/
cat > config/includes.chroot/etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=v

[security]

[xdmcp]

[greeter]
# Hintergrundbild für GDM
BackgroundImage=/usr/share/backgrounds/custom/desktop-background.png

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

# Schriftarten für GRUB vorbereiten
mkdir -p config/includes.binary/boot/grub/fonts/

# Kopiere unicode.pf2 und erstelle einen Symlink auf font.pf2
cp /usr/share/grub/unicode.pf2 config/includes.binary/boot/grub/fonts/ || echo "Unicode font not found, using system default"
cp /usr/share/grub/unicode.pf2 config/includes.binary/boot/grub/font.pf2 || echo "Could not create font.pf2"

# GRUB-Menüeinträge anpassen
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

# Verzeichnis für GNOME Extensions erstellen
mkdir -p config/includes.chroot/usr/share/gnome-shell/extensions/
mkdir -p config/includes.chroot/etc/skel/.local/share/gnome-shell/extensions/

# Hook erstellen, um die GNOME-Extensions herunterzuladen und zu installieren
# Beachte: Wir laden kompatible Versionen für GNOME in Debian Bookworm herunter
cat > config/hooks/live/0020-install-gnome-extensions.hook.chroot << EOF
#!/bin/bash
# GNOME-Extensions herunterladen und installieren

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/extensions-setup.log 2>&1

# GNOME-Version ermitteln
GNOME_VERSION=\$(gnome-shell --version | awk '{print \$3}' | cut -d. -f1,2)
echo "Erkannte GNOME-Version: \$GNOME_VERSION"

# Verzeichnis für Extensions erstellen
mkdir -p /usr/share/gnome-shell/extensions/
mkdir -p /etc/skel/.local/share/gnome-shell/extensions/

# Extensions herunterladen
cd /tmp

# Für Debian Bookworm (GNOME 43) kompatible Versionen laden
if [[ "\$GNOME_VERSION" == "43."* ]]; then
    echo "Lade Extensions für GNOME 43"
    
    # Dash to Dock - Version für GNOME 43
    wget -O dash-to-dock.zip https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v76.shell-extension.zip
    
    # User Theme - Version für GNOME 43
    wget -O user-theme.zip https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v49.shell-extension.zip
else
    echo "Lade allgemeine Versionen der Extensions"
    
    # Dash to Dock - neuere Version
    wget -O dash-to-dock.zip https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v75.shell-extension.zip
    
    # User Theme - neuere Version
    wget -O user-theme.zip https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v49.shell-extension.zip
fi

# Extensions entpacken und installieren
mkdir -p /etc/skel/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
unzip -q dash-to-dock.zip -d /etc/skel/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com

mkdir -p /etc/skel/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
unzip -q user-theme.zip -d /etc/skel/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com

# Auch ins System kopieren für alle Benutzer
cp -r /etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/

# Metadaten für Extensions anpassen, um Kompatibilität sicherzustellen
for ext in /usr/share/gnome-shell/extensions/*/metadata.json /etc/skel/.local/share/gnome-shell/extensions/*/metadata.json; do
    if [ -f "\$ext" ]; then
        # Aktualisiere die shell-version in metadata.json um sicherzustellen, dass Extensions funktionieren
        sed -i "s/\"shell-version\":\s*\[[^]]*\]/\"shell-version\": [\"\$GNOME_VERSION\"]/" "\$ext"
        echo "Aktualisierte \$ext für GNOME \$GNOME_VERSION"
    fi
done

# Berechtigungen korrigieren
chmod -R 755 /etc/skel/.local/share/gnome-shell/extensions/
chmod -R 755 /usr/share/gnome-shell/extensions/

# Extension-Status überprüfen
ls -la /etc/skel/.local/share/gnome-shell/extensions/
ls -la /usr/share/gnome-shell/extensions/

echo "Extensions-Setup abgeschlossen"
EOF
chmod +x config/hooks/live/0020-install-gnome-extensions.hook.chroot

# Ein Skript für die Aktivierung der Erweiterungen nach dem ersten Login erstellen
cat > config/includes.chroot/etc/skel/.config/autostart/delayed-setup.desktop << EOF
[Desktop Entry]
Type=Application
Name=Delayed Setup
Exec=/usr/local/bin/delayed-setup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=10
EOF

# Das eigentliche Skript, das mit Verzögerung ausgeführt wird - verbessert und fehlersicherer
mkdir -p config/includes.chroot/usr/local/bin/
cat > config/includes.chroot/usr/local/bin/delayed-setup.sh << EOF
#!/bin/bash

# Logdatei erstellen
exec > /home/v/delayed-setup.log 2>&1

echo "Delayed Setup startet um $(date)"

# Warte länger, um sicherzustellen, dass GNOME vollständig geladen ist
sleep 30

# Prüfen, ob das Hintergrundbild existiert, sonst neu herunterladen
if [ ! -f /usr/share/backgrounds/custom/desktop-background.png ]; then
  echo "Hintergrundbild fehlt - erstelle Verzeichnis und lade Bild herunter"
  mkdir -p /usr/share/backgrounds/custom/
  curl -o /usr/share/backgrounds/custom/desktop-background.png https://raw.githubusercontent.com/noKrypton/image/main/grub.png
  # Kopie im Home-Verzeichnis
  cp /usr/share/backgrounds/custom/desktop-background.png /home/v/desktop-background.png
fi

echo "Setze Desktop-Hintergrund"
# Desktop Hintergrund setzen - absolute URI-Pfade verwenden
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/custom/desktop-background.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/custom/desktop-background.png"

echo "Debugging-Informationen sammeln"
# Zeige alle installierten Themes
ls -la /usr/share/themes/
echo "Red Theme Inhalt:"
ls -la /usr/share/themes/Red-Theme/

# Zeige alle installierten Extensions
echo "Installierte Extensions:"
ls -la ~/.local/share/gnome-shell/extensions/
ls -la /usr/share/gnome-shell/extensions/

echo "Setze Dark Mode"
# Dark Mode setzen
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Red-Theme'

echo "Setze Terminal-Einstellungen"
# Terminal-Einstellungen
profile=\$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ background-color 'rgb(0,0,0)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ foreground-color 'rgb(255,255,255)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ use-theme-colors false

echo "Aktiviere Extensions"
# Extensions aktivieren
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable dash-to-dock@micxgx.gmail.com

echo "Setze User Theme"
# User Theme setzen
gsettings set org.gnome.shell.extensions.user-theme name 'Red-Theme'

echo "Konfiguriere Dash to Dock als abgerundetes Viereck"
# Dash to Dock Einstellungen für abgerundetes Viereck in der Mitte
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.7
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.5
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top false

echo "Aktiviere Extensions in GNOME Shell"
# Stelle sicher, dass die Extensions aktiviert sind
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']"

echo "Delayed Setup abgeschlossen um $(date)"
EOF
chmod +x config/includes.chroot/usr/local/bin/delayed-setup.sh

# Zusätzliches Hook für permanente Einstellungen erstellen
cat > config/hooks/live/0030-persistent-settings.hook.chroot << EOF
#!/bin/bash
# Permanente Einstellungen für alle Benutzer und GDM

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/persistent-settings.log 2>&1

# Systemweite GTK-Einstellungen
mkdir -p /etc/gtk-3.0/
cat > /etc/gtk-3.0/settings.ini << EOF2
[Settings]
gtk-theme-name=Red-Theme
gtk-application-prefer-dark-theme=1
EOF2

# Hintergrundbild auch nach /usr/share/images kopieren
mkdir -p /usr/share/images/
cp /usr/share/backgrounds/custom/desktop-background.png /usr/share/images/

# Hintergrundbild auch für GDM verfügbar machen
mkdir -p /usr/share/backgrounds/gnome/
cp /usr/share/backgrounds/custom/desktop-background.png /usr/share/backgrounds/gnome/

# Hintergrundbild für GDM konfigurieren
mkdir -p /etc/dconf/db/gdm.d/
cat > /etc/dconf/db/gdm.d/01-background << EOF2
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/desktop-background.png'
picture-uri-dark='file:///usr/share/backgrounds/custom/desktop-background.png'

[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Red-Theme'
EOF2

echo "system-db:gdm" > /etc/dconf/profile/gdm

# GDM.css anpassen für rotes Theme
mkdir -p /usr/share/gnome-shell/theme/
if [ -f /usr/share/gnome-shell/theme/gdm.css ]; then
  cp /usr/share/gnome-shell/theme/gdm.css /usr/share/gnome-shell/theme/gdm.css.bak
  sed -i 's/#panel {.*}/\#panel { background-color: rgba(200, 0, 0, 0.8); }/' /usr/share/gnome-shell/theme/gdm.css
fi

# Dconf-Datenbank aktualisieren
dconf update || echo "dconf update fehlgeschlagen"

echo "Permanente Einstellungen abgeschlossen"
EOF
chmod +x config/hooks/live/0030-persistent-settings.hook.chroot

# Erstelle einen Hook für Fenster-Theme (nicht-transparente Titelleisten)
cat > config/hooks/live/0040-window-theme.hook.chroot << EOF
#!/bin/bash
# Fenster-Einstellungen konfigurieren (nicht-transparente Titelleisten)

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/window-theme.log 2>&1

# CSS-Datei für Metacity-Theme erstellen
mkdir -p /usr/share/themes/Red-Theme/metacity-1/
cat > /usr/share/themes/Red-Theme/metacity-1/metacity-theme-3.xml << EOF2
<?xml version="1.0" encoding="UTF-8"?>
<metacity_theme>
  <info>
    <name>Red-Theme</name>
    <author>System</author>
    <copyright>GPL</copyright>
    <description>Red Theme for Metacity</description>
  </info>
  
  <frame_geometry name="normal" rounded_top_left="true" rounded_top_right="true" rounded_bottom_left="false" rounded_bottom_right="false">
    <distance name="left_width" value="1"/>
    <distance name="right_width" value="1"/>
    <distance name="bottom_height" value="1"/>
    <distance name="top_height" value="24"/>
    <distance name="title_vertical_pad" value="3"/>
    <border name="title_border" left="10" right="10" top="0" bottom="0"/>
    <border name="button_border" left="0" right="0" top="0" bottom="0"/>
  </frame_geometry>
  
  <draw_ops name="title_text">
    <title color="#ffffff" x="(width - title_width) / 2" y="(height - title_height) / 2"/>
  </draw_ops>
  
  <draw_ops name="title_bg">
    <rectangle color="#CC0000" x="0" y="0" width="width" height="height" filled="true"/>
  </draw_ops>
  
  <frame_style name="normal" geometry="normal">
    <piece position="titlebar" draw_ops="title_bg"/>
    <piece position="title" draw_ops="title_text"/>
  </frame_style>
  
  <frame_style_set name="normal">
    <frame focus="yes" state="normal" style="normal"/>
    <frame focus="no" state="normal" style="normal"/>
    <frame focus="yes" state="maximized" style="normal"/>
    <frame focus="no" state="maximized" style="normal"/>
  </frame_style_set>
  
  <window type="normal" style_set="normal"/>
  <window type="dialog" style_set="normal"/>
  <window type="modal_dialog" style_set="normal"/>
  <window type="menu" style_set="normal"/>
  <window type="utility" style_set="normal"/>
  <window type="border" style_set="normal"/>
</metacity_theme>
EOF2

# Erstelle GTK-CSS für nicht-transparente Fenster
cat > /usr/share/themes/Red-Theme/gtk-3.0/gtk-custom.css << EOF2
/* Anpassungen für nicht-transparente Titelleisten */
/* Anpassungen für nicht-transparente Titelleisten */
headerbar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.solid-csd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.ssd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.titlebar:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.window-frame {
    box-shadow: none;
    margin: 0;
    border: none;
    opacity: 1.0;
}

decoration {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

decoration:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}
EOF2

# CSS für GTK-4 Anwendungen vorbereiten
mkdir -p /usr/share/themes/Red-Theme/gtk-4.0/
cat > /usr/share/themes/Red-Theme/gtk-4.0/gtk.css << EOF2
/* Red Theme für GTK 4.0 */
@import url("resource:///org/gnome/theme/Adwaita-dark.css");

/* Anpassungen für das rote Theme */
@define-color theme_selected_bg_color #CC0000;
@define-color theme_selected_fg_color #FFFFFF;

/* Anpassungen für nicht-transparente Titelleisten */
.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

headerbar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.solid-csd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.ssd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.titlebar:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.window-frame {
    box-shadow: none;
    margin: 0;
    border: none;
    opacity: 1.0;
}

decoration {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

decoration:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}
EOF2

echo "Fenster-Theme-Setup abgeschlossen"
EOF
chmod +x config/hooks/live/0040-window-theme.hook.chroot

# Ein zusätzliches Skript erstellen für den Fall, dass es beim ersten Start Probleme gibt
mkdir -p config/includes.chroot/home/v/
cat > config/includes.chroot/home/v/fix-theme.sh << EOF
#!/bin/bash
# Dieses Skript kann manuell ausgeführt werden, wenn das Theme nicht korrekt geladen wurde

# GNOME-Version ermitteln
GNOME_VERSION=\$(gnome-shell --version | awk '{print \$3}' | cut -d. -f1,2)
echo "GNOME-Version: \$GNOME_VERSION"

# Hintergrundbild neu setzen
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/custom/desktop-background.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/custom/desktop-background.png"

# Theme neu setzen
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Red-Theme'

# Extensions reaktivieren
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable dash-to-dock@micxgx.gmail.com

# Extensions-Kompatibilität verbessern
for ext in ~/.local/share/gnome-shell/extensions/*/metadata.json; do
    if [ -f "\$ext" ]; then
        # Update the shell-version to ensure compatibility
        sed -i "s/\"shell-version\":\s*\[[^]]*\]/\"shell-version\": [\"\$GNOME_VERSION\"]/" "\$ext"
        echo "Aktualisierte \$ext für GNOME \$GNOME_VERSION"
    fi
done

# User Theme setzen
gsettings set org.gnome.shell.extensions.user-theme name 'Red-Theme'

# Konfiguriere Dash to Dock als abgerundetes Viereck in der Mitte
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.7
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.5
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false

echo "Theme-Reparatur abgeschlossen. Es wird empfohlen, sich abzumelden und neu anzumelden, damit alle Änderungen wirksam werden."
EOF
chmod +x config/includes.chroot/home/v/fix-theme.sh

# Hook erstellen, um Berechtigungen für den Live-Benutzer zu setzen
cat > config/hooks/live/9999-fix-permissions.hook.chroot << EOF
#!/bin/bash
# Berechtigungen für das Home-Verzeichnis des Live-Benutzers korrigieren

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/fix-permissions.log 2>&1

# Der Live-Benutzer hat UID 1000
mkdir -p /home/v/
chown -R 1000:1000 /home/v/

# Kopiere das Fix-Skript nach /home/v/, falls es dort nicht ist
cp /etc/skel/fix-theme.sh /home/v/ 2>/dev/null || true
chmod +x /home/v/fix-theme.sh
chown 1000:1000 /home/v/fix-theme.sh

echo "Berechtigungen korrigiert"
EOF
chmod +x config/hooks/live/9999-fix-permissions.hook.chroot

echo "Konfiguration abgeschlossen. Starte den Build-Prozess..."
# Live-Build ausführen
lb build

echo "Debian Live ISO wurde erstellt. Die Datei befindet sich im aktuellen Verzeichnis."#!/bin/bash

# Dieses Skript erstellt ein angepasstes Debian Live-System mit GNOME und eigenem Hintergrundbild
# sowie einem benutzerdefinierten GRUB-Hintergrundbild und Dark Mode aktiviert

# Benötigte Pakete installieren
sudo apt-get update
sudo apt-get install -y live-build live-config live-boot curl

# Arbeitsverzeichnis erstellen
mkdir -p debian-live-custom
cd debian-live-custom

# Altes Build-Verzeichnis säubern, falls vorhanden
sudo lb clean --all 2>/dev/null || true

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
gdm3
firmware-linux
curl
grub2-common
grub-common
tor
torbrowser-launcher
wireshark
nmap
aircrack-ng
git
curl
wget
gnome-shell-extensions
unzip
gnome-tweaks
dconf-cli
dconf-editor
EOF

# Verzeichnisstruktur für Hintergrundbilder erstellen
mkdir -p config/includes.chroot/usr/share/backgrounds/custom
mkdir -p config/includes.chroot/etc/skel/.config/
mkdir -p config/includes.binary/boot/grub/

# GRUB und Desktop Hintergrundbild herunterladen
# Lokale Kopie herunterladen und speichern
curl -o grub-background.png https://raw.githubusercontent.com/noKrypton/image/main/grub.png
cp grub-background.png config/includes.binary/boot/grub/grub-background.png
cp grub-background.png config/includes.chroot/usr/share/backgrounds/custom/desktop-background.png

# GNOME Dconf-Einstellungen-Verzeichnis erstellen
mkdir -p config/includes.chroot/etc/skel/.config/dconf/
mkdir -p config/includes.chroot/etc/skel/.config/autostart/

# Rotes Theme erstellen
mkdir -p config/includes.chroot/usr/share/themes/Red-Theme/gnome-shell/
cat > config/includes.chroot/usr/share/themes/Red-Theme/gnome-shell/gnome-shell.css << EOF
/* Red Theme for GNOME Shell */
stage {
    color: #ffffff;
}

.panel-button {
    color: #ffffff;
}

#panel {
    background-color: rgba(200, 0, 0, 0.8);
    color: #ffffff;
}

/* Titel-Leisten nicht transparent machen */
.window-frame {
    background-color: rgba(200, 0, 0, 1.0);
    border: none;
}

.header-bar {
    background-color: rgba(200, 0, 0, 1.0);
    border: none;
}

.titlebar {
    background-color: rgba(200, 0, 0, 1.0);
    border: none;
}

/* Dash-Anpassungen für das abgerundete Viereck */
.dash-background {
    background-color: rgba(200, 0, 0, 0.7);
    border: 1px solid rgba(255, 80, 80, 0.7);
    border-radius: 24px;
    margin-left: 15%;
    margin-right: 15%;
    margin-bottom: 10px;
}

.dash {
    margin-left: 15%;
    margin-right: 15%;
}

.app-well-app:hover .overview-icon,
.app-well-app:focus .overview-icon,
.app-well-app:selected .overview-icon {
    background-color: rgba(255, 100, 100, 0.5);
}

.search-entry {
    background-color: rgba(200, 0, 0, 0.3);
    border-color: rgba(255, 100, 100, 0.5);
    color: #ffffff;
}

/* Andere Elemente können hier angepasst werden */
EOF

# Stylesheet-Datei für das Theme erstellen
mkdir -p config/includes.chroot/usr/share/themes/Red-Theme/gtk-3.0/
cat > config/includes.chroot/usr/share/themes/Red-Theme/gtk-3.0/gtk.css << EOF
/* Red Theme for GTK 3.0 */
@import url("resource:///org/gnome/theme/Adwaita-dark.css");

/* Anpassungen für das rote Theme */
@define-color theme_selected_bg_color #CC0000;
@define-color theme_selected_fg_color #FFFFFF;

/* Titel-Leisten nicht transparent machen */
headerbar {
    background-color: @theme_selected_bg_color;
    border: none;
}

.titlebar {
    background-color: @theme_selected_bg_color;
    border: none;
}

window.solid-csd headerbar.titlebar {
    background-color: @theme_selected_bg_color;
    border: none;
}

window.ssd headerbar.titlebar {
    background-color: @theme_selected_bg_color;
    border: none;
}
EOF

# Theme Index-Datei hinzufügen
mkdir -p config/includes.chroot/usr/share/themes/Red-Theme/
cat > config/includes.chroot/usr/share/themes/Red-Theme/index.theme << EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Red-Theme
Comment=Red custom theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Red-Theme
MetacityTheme=Adwaita
IconTheme=Adwaita
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:
EOF

# Hook erstellen, um Dark Mode und Terminal-Einstellungen zu konfigurieren
mkdir -p config/hooks/live/
cat > config/hooks/live/0015-configure-dark-mode.hook.chroot << EOF
#!/bin/bash
# Dark Mode und andere GNOME-Einstellungen konfigurieren

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/dark-mode-setup.log 2>&1

# Erstelle das Verzeichnis für den Live-Benutzer
mkdir -p /etc/skel/.config/dconf/

# GNOME Systemweite Einstellungen
mkdir -p /etc/dconf/db/local.d/
mkdir -p /etc/dconf/profile/

# dconf-Profile konfigurieren
echo "user-db:user
system-db:local" > /etc/dconf/profile/user

# Erstelle eine dconf-Systemweite Datenbank für die Standardeinstellungen
cat > /etc/dconf/db/local.d/00-desktop << EOF2
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Red-Theme'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/desktop-background.png'
picture-uri-dark='file:///usr/share/backgrounds/custom/desktop-background.png'

[org/gnome/terminal/legacy/profiles:]
default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
background-color='rgb(0,0,0)'
foreground-color='rgb(255,255,255)'
use-theme-colors=false

[org/gnome/shell]
enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']

[org/gnome/shell/extensions/user-theme]
name='Red-Theme'

[org/gnome/shell/extensions/dash-to-dock]
dock-fixed=true
extend-height=false
transparency-mode='FIXED'
background-opacity=0.7
dash-max-icon-size=48
dock-position='BOTTOM'
preferred-monitor=0
custom-theme-shrink=true
height-fraction=0.5
require-pressure-to-show=false
pressure-threshold=0
intellihide=false
show-trash=false
show-mounts=false
show-apps-at-top=false
show-show-apps-button=true
multi-monitor=false
EOF2

# Für den Benutzer in einem Format, das dconf direkt verwenden kann
mkdir -p /etc/skel/.config/dconf/
cat > /etc/skel/.config/dconf/user.db << EOF2
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Red-Theme'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/desktop-background.png'
picture-uri-dark='file:///usr/share/backgrounds/custom/desktop-background.png'

[org/gnome/terminal/legacy/profiles:]
default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
background-color='rgb(0,0,0)'
foreground-color='rgb(255,255,255)'
use-theme-colors=false

[org/gnome/shell]
enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']

[org/gnome/shell/extensions/user-theme]
name='Red-Theme'

[org/gnome/shell/extensions/dash-to-dock]
dock-fixed=true
extend-height=false
transparency-mode='FIXED'
background-opacity=0.7
dash-max-icon-size=48
dock-position='BOTTOM'
preferred-monitor=0
custom-theme-shrink=true
height-fraction=0.5
require-pressure-to-show=false
pressure-threshold=0
intellihide=false
show-trash=false
show-mounts=false
show-apps-at-top=false
show-show-apps-button=true
multi-monitor=false
EOF2

# Hintergrundbild kopieren (redundant, aber sicherer)
cp /usr/share/backgrounds/custom/desktop-background.png /etc/skel/desktop-background.png

# Erstellen Sie ein Skript, das bei jedem Login ausgeführt wird
mkdir -p /etc/profile.d/
cat > /etc/profile.d/gnome-settings.sh << EOF2
#!/bin/bash
# Gnome-Einstellungen bei jedem Login anwenden
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Red-Theme'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/custom/desktop-background.png'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/custom/desktop-background.png'
EOF2
chmod +x /etc/profile.d/gnome-settings.sh

# Dconf-Datenbank aktualisieren
dconf update || echo "dconf update fehlgeschlagen"

# Stelle sicher, dass die Berechtigungen korrekt sind
chmod -R 755 /etc/skel/.config/
chmod 644 /etc/skel/.config/dconf/user.db

echo "Dark-Mode-Setup abgeschlossen" 
EOF
chmod +x config/hooks/live/0015-configure-dark-mode.hook.chroot

# GDM-Konfiguration für automatischen Login
mkdir -p config/includes.chroot/etc/gdm3/
cat > config/includes.chroot/etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=v

[security]

[xdmcp]

[greeter]
# Hintergrundbild für GDM
BackgroundImage=/usr/share/backgrounds/custom/desktop-background.png

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

# Schriftarten für GRUB vorbereiten
mkdir -p config/includes.binary/boot/grub/fonts/

# Kopiere unicode.pf2 und erstelle einen Symlink auf font.pf2
cp /usr/share/grub/unicode.pf2 config/includes.binary/boot/grub/fonts/ || echo "Unicode font not found, using system default"
cp /usr/share/grub/unicode.pf2 config/includes.binary/boot/grub/font.pf2 || echo "Could not create font.pf2"

# GRUB-Menüeinträge anpassen
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

# Verzeichnis für GNOME Extensions erstellen
mkdir -p config/includes.chroot/usr/share/gnome-shell/extensions/
mkdir -p config/includes.chroot/etc/skel/.local/share/gnome-shell/extensions/

# Hook erstellen, um die GNOME-Extensions herunterzuladen und zu installieren
# Beachte: Wir laden kompatible Versionen für GNOME in Debian Bookworm herunter
cat > config/hooks/live/0020-install-gnome-extensions.hook.chroot << EOF
#!/bin/bash
# GNOME-Extensions herunterladen und installieren

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/extensions-setup.log 2>&1

# GNOME-Version ermitteln
GNOME_VERSION=\$(gnome-shell --version | awk '{print \$3}' | cut -d. -f1,2)
echo "Erkannte GNOME-Version: \$GNOME_VERSION"

# Verzeichnis für Extensions erstellen
mkdir -p /usr/share/gnome-shell/extensions/
mkdir -p /etc/skel/.local/share/gnome-shell/extensions/

# Extensions herunterladen
cd /tmp

# Für Debian Bookworm (GNOME 43) kompatible Versionen laden
if [[ "\$GNOME_VERSION" == "43."* ]]; then
    echo "Lade Extensions für GNOME 43"
    
    # Dash to Dock - Version für GNOME 43
    wget -O dash-to-dock.zip https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v76.shell-extension.zip
    
    # User Theme - Version für GNOME 43
    wget -O user-theme.zip https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v49.shell-extension.zip
else
    echo "Lade allgemeine Versionen der Extensions"
    
    # Dash to Dock - neuere Version
    wget -O dash-to-dock.zip https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v75.shell-extension.zip
    
    # User Theme - neuere Version
    wget -O user-theme.zip https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v49.shell-extension.zip
fi

# Extensions entpacken und installieren
mkdir -p /etc/skel/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
unzip -q dash-to-dock.zip -d /etc/skel/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com

mkdir -p /etc/skel/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
unzip -q user-theme.zip -d /etc/skel/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com

# Auch ins System kopieren für alle Benutzer
cp -r /etc/skel/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/

# Metadaten für Extensions anpassen, um Kompatibilität sicherzustellen
for ext in /usr/share/gnome-shell/extensions/*/metadata.json /etc/skel/.local/share/gnome-shell/extensions/*/metadata.json; do
    if [ -f "\$ext" ]; then
        # Aktualisiere die shell-version in metadata.json um sicherzustellen, dass Extensions funktionieren
        sed -i "s/\"shell-version\":\s*\[[^]]*\]/\"shell-version\": [\"\$GNOME_VERSION\"]/" "\$ext"
        echo "Aktualisierte \$ext für GNOME \$GNOME_VERSION"
    fi
done

# Berechtigungen korrigieren
chmod -R 755 /etc/skel/.local/share/gnome-shell/extensions/
chmod -R 755 /usr/share/gnome-shell/extensions/

# Extension-Status überprüfen
ls -la /etc/skel/.local/share/gnome-shell/extensions/
ls -la /usr/share/gnome-shell/extensions/

echo "Extensions-Setup abgeschlossen"
EOF
chmod +x config/hooks/live/0020-install-gnome-extensions.hook.chroot

# Ein Skript für die Aktivierung der Erweiterungen nach dem ersten Login erstellen
cat > config/includes.chroot/etc/skel/.config/autostart/delayed-setup.desktop << EOF
[Desktop Entry]
Type=Application
Name=Delayed Setup
Exec=/usr/local/bin/delayed-setup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=10
EOF

# Das eigentliche Skript, das mit Verzögerung ausgeführt wird - verbessert und fehlersicherer
mkdir -p config/includes.chroot/usr/local/bin/
cat > config/includes.chroot/usr/local/bin/delayed-setup.sh << EOF
#!/bin/bash

# Logdatei erstellen
exec > /home/v/delayed-setup.log 2>&1

echo "Delayed Setup startet um $(date)"

# Warte länger, um sicherzustellen, dass GNOME vollständig geladen ist
sleep 30

# Prüfen, ob das Hintergrundbild existiert, sonst neu herunterladen
if [ ! -f /usr/share/backgrounds/custom/desktop-background.png ]; then
  echo "Hintergrundbild fehlt - erstelle Verzeichnis und lade Bild herunter"
  mkdir -p /usr/share/backgrounds/custom/
  curl -o /usr/share/backgrounds/custom/desktop-background.png https://raw.githubusercontent.com/noKrypton/image/main/grub.png
  # Kopie im Home-Verzeichnis
  cp /usr/share/backgrounds/custom/desktop-background.png /home/v/desktop-background.png
fi

echo "Setze Desktop-Hintergrund"
# Desktop Hintergrund setzen - absolute URI-Pfade verwenden
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/custom/desktop-background.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/custom/desktop-background.png"

echo "Debugging-Informationen sammeln"
# Zeige alle installierten Themes
ls -la /usr/share/themes/
echo "Red Theme Inhalt:"
ls -la /usr/share/themes/Red-Theme/

# Zeige alle installierten Extensions
echo "Installierte Extensions:"
ls -la ~/.local/share/gnome-shell/extensions/
ls -la /usr/share/gnome-shell/extensions/

echo "Setze Dark Mode"
# Dark Mode setzen
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Red-Theme'

echo "Setze Terminal-Einstellungen"
# Terminal-Einstellungen
profile=\$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ background-color 'rgb(0,0,0)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ foreground-color 'rgb(255,255,255)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"\$profile"/ use-theme-colors false

echo "Aktiviere Extensions"
# Extensions aktivieren
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable dash-to-dock@micxgx.gmail.com

echo "Setze User Theme"
# User Theme setzen
gsettings set org.gnome.shell.extensions.user-theme name 'Red-Theme'

echo "Konfiguriere Dash to Dock als abgerundetes Viereck"
# Dash to Dock Einstellungen für abgerundetes Viereck in der Mitte
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.7
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.5
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top false

echo "Aktiviere Extensions in GNOME Shell"
# Stelle sicher, dass die Extensions aktiviert sind
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']"

echo "Delayed Setup abgeschlossen um $(date)"
EOF
chmod +x config/includes.chroot/usr/local/bin/delayed-setup.sh

# Zusätzliches Hook für permanente Einstellungen erstellen
cat > config/hooks/live/0030-persistent-settings.hook.chroot << EOF
#!/bin/bash
# Permanente Einstellungen für alle Benutzer und GDM

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/persistent-settings.log 2>&1

# Systemweite GTK-Einstellungen
mkdir -p /etc/gtk-3.0/
cat > /etc/gtk-3.0/settings.ini << EOF2
[Settings]
gtk-theme-name=Red-Theme
gtk-application-prefer-dark-theme=1
EOF2

# Hintergrundbild auch nach /usr/share/images kopieren
mkdir -p /usr/share/images/
cp /usr/share/backgrounds/custom/desktop-background.png /usr/share/images/

# Hintergrundbild auch für GDM verfügbar machen
mkdir -p /usr/share/backgrounds/gnome/
cp /usr/share/backgrounds/custom/desktop-background.png /usr/share/backgrounds/gnome/

# Hintergrundbild für GDM konfigurieren
mkdir -p /etc/dconf/db/gdm.d/
cat > /etc/dconf/db/gdm.d/01-background << EOF2
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/custom/desktop-background.png'
picture-uri-dark='file:///usr/share/backgrounds/custom/desktop-background.png'

[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Red-Theme'
EOF2

echo "system-db:gdm" > /etc/dconf/profile/gdm

# GDM.css anpassen für rotes Theme
mkdir -p /usr/share/gnome-shell/theme/
if [ -f /usr/share/gnome-shell/theme/gdm.css ]; then
  cp /usr/share/gnome-shell/theme/gdm.css /usr/share/gnome-shell/theme/gdm.css.bak
  sed -i 's/#panel {.*}/\#panel { background-color: rgba(200, 0, 0, 0.8); }/' /usr/share/gnome-shell/theme/gdm.css
fi

# Dconf-Datenbank aktualisieren
dconf update || echo "dconf update fehlgeschlagen"

echo "Permanente Einstellungen abgeschlossen"
EOF
chmod +x config/hooks/live/0030-persistent-settings.hook.chroot

# Erstelle einen Hook für Fenster-Theme (nicht-transparente Titelleisten)
cat > config/hooks/live/0040-window-theme.hook.chroot << EOF
#!/bin/bash
# Fenster-Einstellungen konfigurieren (nicht-transparente Titelleisten)

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/window-theme.log 2>&1

# CSS-Datei für Metacity-Theme erstellen
mkdir -p /usr/share/themes/Red-Theme/metacity-1/
cat > /usr/share/themes/Red-Theme/metacity-1/metacity-theme-3.xml << EOF2
<?xml version="1.0" encoding="UTF-8"?>
<metacity_theme>
  <info>
    <name>Red-Theme</name>
    <author>System</author>
    <copyright>GPL</copyright>
    <description>Red Theme for Metacity</description>
  </info>
  
  <frame_geometry name="normal" rounded_top_left="true" rounded_top_right="true" rounded_bottom_left="false" rounded_bottom_right="false">
    <distance name="left_width" value="1"/>
    <distance name="right_width" value="1"/>
    <distance name="bottom_height" value="1"/>
    <distance name="top_height" value="24"/>
    <distance name="title_vertical_pad" value="3"/>
    <border name="title_border" left="10" right="10" top="0" bottom="0"/>
    <border name="button_border" left="0" right="0" top="0" bottom="0"/>
  </frame_geometry>
  
  <draw_ops name="title_text">
    <title color="#ffffff" x="(width - title_width) / 2" y="(height - title_height) / 2"/>
  </draw_ops>
  
  <draw_ops name="title_bg">
    <rectangle color="#CC0000" x="0" y="0" width="width" height="height" filled="true"/>
  </draw_ops>
  
  <frame_style name="normal" geometry="normal">
    <piece position="titlebar" draw_ops="title_bg"/>
    <piece position="title" draw_ops="title_text"/>
  </frame_style>
  
  <frame_style_set name="normal">
    <frame focus="yes" state="normal" style="normal"/>
    <frame focus="no" state="normal" style="normal"/>
    <frame focus="yes" state="maximized" style="normal"/>
    <frame focus="no" state="maximized" style="normal"/>
  </frame_style_set>
  
  <window type="normal" style_set="normal"/>
  <window type="dialog" style_set="normal"/>
  <window type="modal_dialog" style_set="normal"/>
  <window type="menu" style_set="normal"/>
  <window type="utility" style_set="normal"/>
  <window type="border" style_set="normal"/>
</metacity_theme>
EOF2

# Erstelle GTK-CSS für nicht-transparente Fenster
cat > /usr/share/themes/Red-Theme/gtk-3.0/gtk-custom.css << EOF2
/* Anpassungen für nicht-transparente Titelleisten */
/* Anpassungen für nicht-transparente Titelleisten */
headerbar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.solid-csd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.ssd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.titlebar:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.window-frame {
    box-shadow: none;
    margin: 0;
    border: none;
    opacity: 1.0;
}

decoration {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

decoration:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}
EOF2

# CSS für GTK-4 Anwendungen vorbereiten
mkdir -p /usr/share/themes/Red-Theme/gtk-4.0/
cat > /usr/share/themes/Red-Theme/gtk-4.0/gtk.css << EOF2
/* Red Theme für GTK 4.0 */
@import url("resource:///org/gnome/theme/Adwaita-dark.css");

/* Anpassungen für das rote Theme */
@define-color theme_selected_bg_color #CC0000;
@define-color theme_selected_fg_color #FFFFFF;

/* Anpassungen für nicht-transparente Titelleisten */
.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

headerbar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.solid-csd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

window.ssd headerbar.titlebar {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.titlebar:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

.window-frame {
    box-shadow: none;
    margin: 0;
    border: none;
    opacity: 1.0;
}

decoration {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}

decoration:backdrop {
    background-color: #CC0000;
    border: none;
    opacity: 1.0;
}
EOF2

echo "Fenster-Theme-Setup abgeschlossen"
EOF
chmod +x config/hooks/live/0040-window-theme.hook.chroot

# Ein zusätzliches Skript erstellen für den Fall, dass es beim ersten Start Probleme gibt
mkdir -p config/includes.chroot/home/v/
cat > config/includes.chroot/home/v/fix-theme.sh << EOF
#!/bin/bash
# Dieses Skript kann manuell ausgeführt werden, wenn das Theme nicht korrekt geladen wurde

# GNOME-Version ermitteln
GNOME_VERSION=\$(gnome-shell --version | awk '{print \$3}' | cut -d. -f1,2)
echo "GNOME-Version: \$GNOME_VERSION"

# Hintergrundbild neu setzen
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/custom/desktop-background.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/custom/desktop-background.png"

# Theme neu setzen
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Red-Theme'

# Extensions reaktivieren
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable dash-to-dock@micxgx.gmail.com

# Extensions-Kompatibilität verbessern
for ext in ~/.local/share/gnome-shell/extensions/*/metadata.json; do
    if [ -f "\$ext" ]; then
        # Update the shell-version to ensure compatibility
        sed -i "s/\"shell-version\":\s*\[[^]]*\]/\"shell-version\": [\"\$GNOME_VERSION\"]/" "\$ext"
        echo "Aktualisierte \$ext für GNOME \$GNOME_VERSION"
    fi
done

# User Theme setzen
gsettings set org.gnome.shell.extensions.user-theme name 'Red-Theme'

# Konfiguriere Dash to Dock als abgerundetes Viereck in der Mitte
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.7
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.5
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false

echo "Theme-Reparatur abgeschlossen. Es wird empfohlen, sich abzumelden und neu anzumelden, damit alle Änderungen wirksam werden."
EOF
chmod +x config/includes.chroot/home/v/fix-theme.sh

# Hook erstellen, um Berechtigungen für den Live-Benutzer zu setzen
cat > config/hooks/live/9999-fix-permissions.hook.chroot << EOF
#!/bin/bash
# Berechtigungen für das Home-Verzeichnis des Live-Benutzers korrigieren

# Debug-Ausgabe aktivieren
set -x
exec > /var/log/fix-permissions.log 2>&1

# Der Live-Benutzer hat UID 1000
mkdir -p /home/v/
chown -R 1000:1000 /home/v/

# Kopiere das Fix-Skript nach /home/v/, falls es dort nicht ist
cp /etc/skel/fix-theme.sh /home/v/ 2>/dev/null || true
chmod +x /home/v/fix-theme.sh
chown 1000:1000 /home/v/fix-theme.sh

echo "Berechtigungen korrigiert"
EOF
chmod +x config/hooks/live/9999-fix-permissions.hook.chroot

echo "Konfiguration abgeschlossen. Starte den Build-Prozess..."
# Live-Build ausführen
lb build

echo "Debian Live ISO wurde erstellt. Die Datei befindet sich im aktuellen Verzeichnis."

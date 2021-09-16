# PinePhone  
This repo contains my notes for using the [PinePhone](https://www.pine64.org/pinephone/). It includes some steps for setting up [Arch Linux](https://github.com/dreemurrs-embedded/Pine64-Arch) the way I like it, and some workarounds to compensate for things that aren't quite working yet on the [PinePhone](https://www.pine64.org/pinephone/) out of the box. These notes are mainly for me, but they're up here incase they may be useful to anyone else :)


![neofetch_pinephone](https://user-images.githubusercontent.com/8961705/133648326-79f331c2-b74b-4833-bcfa-caf28118d444.png)

I've been using my [PinePhone](https://www.pine64.org/pinephone/) as my daily driver since July 1st, 2021.


## Installation  
[Dreemurrs's](https://github.com/dreemurrs-embedded) script for installing Arch on the PinePhone/PineTab with full disk encryption works perfectly. It can be found here -> [archarm-mobile-fde-installer](https://github.com/dreemurrs-embedded/archarm-mobile-fde-installer). 

## Initial Setup  

### Done with phone in hand.
1. Get things updated with `sudo pacman -Syu`.
2. Enable ssh `sudo systemctl start sshd.service`, only do this at home while you've got password auth enabled (especially with password `123456`).

### Done via SSH.
0. SSH in to do the rest of this so that it's not all phone screen typing nonsense.
1. Change password for alarm user (keep numeric so pin works) `passwd`. Then `su root` and `passwd` to change the root password...then exit.
2. Make ssh directory `mkdir ~/.ssh`.
3. Install some usefull stuff via `sudo pacman -S wget vim`
4. Download keys for key auth `wget https://github.com/d0n601.keys -O ~/.ssh/authorized_keys`.
5. Exit the session and ssh in again with no password to verify functionality.
6. Disable password authentication to ssh via `sudo vim /etc/ssh/sshd_config`, and setting `PasswordAuthentication no`.

### Install GUI File Browser
1. `sudo pacman -S nemo`

### Install Gnome Podcasts
1. `sudo pacman -S gnome-podcasts`

### Install and Enable Cronie
1. `sudo pacman -S cronie`
2. `sudo systemctl enable cronie.service`

### Install and Configure zsh  
0. Install zsh and git via `sudo pacman -S zsh git`.
1. Install [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) via `sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`.
2. Set my favorite theme via `ZSH_THEME="duellj"` in `~/.zshrc`.
3. Clone [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) plugin `git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`
4. Set very convenient auto suggestion plugin via  `plugins=(git zsh-autosuggestions)` in `~/.zshrc`.
5. **Bonus:** `sudo pacman -S cowfortune` and add `cowfortune` to the bottom of `~/.zshrc`.

### Gnome Icons   
I used Manjaro with Posh for a while before switching to Arch, and I missed the look of the default Manjaro setup.   
1. Clone the repo `git clone https://github.com/Ste74/papirus-maia-icon-theme.git`.
2. Make the directory icon `sudo mkdir /usr/share/icons/Papirus-Dark-Maia`.
3. Copy all the files from the dark theme over `sudo cp -R ./papirus-maia-icon-theme/Papirus-Dark-Maia/* /usr/share/icons/Papirus-Dark-Maia`.
4. Set the icons `gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark-Maia"`.
5. Reboot.


### Bluetooth Audio  
Some headphones worked, some didn't. I found the steps below allowed me to pair the nicer set of headphones I've got that weren't working before.  
1. Install Pulas Audio Bluetooth `sudo pacman -S pulseaudio-bluetooth`.
2. Add `Enable=Source,Sink,Media,Socket` to `[General]` section of `/etc/bluetooth/main.conf`.
3. Then `pulseaudio -k`.


### Wifi Hot HotSpot
`sudo nmcli device wifi hotspot ifname wlan0 con-name Hotspot ssid YOURKOOLSSID password APASSWORDHERE`


## Workarounds  
This sections is for temporary workarounds for things that aren't quite working on the PinePhone as of writing this. Hopefully this section will dwindle away to `null` in the future.


### Desktop Apps  
While there aren't many applications with a GUI built for mobile devices, it's helpful to use desktop apps in "scale-to-fit" mode (if your eyesight is good enough).

1. `gsettings set sm.puri.phoc scale-to-fit true`


### Protonmail Bridge  
1. Clone repo here via  `git clone https://github.com/ProtonMail/proton-bridge.git`
2. Install dependencies `sudo pacman -S gcc libsecret go`.


### Alarm Clock  
Right now the alarm clock won't wake the phone from deep sleep, which means it will not work as an alarm clock. Currently Posh users can install the [birdie](https://github.com/Dejvino/birdie) app instead, which works excellent. I [forked](https://github.com/d0n601/birdie) it to change the alarm sound to the more familar Ubuntu Touch alarm I'm used to, and to increase the snooze time significantly ;)
0. Install dependencies if you've not done so already via `sudo pacman -S python-pip make gcc`.
2. Clone the original, or in this case my fork, via `git clone https://github.com/d0n601/birdie`.
3. Move into the directory `cd birdie`.
4. Install the dependencies via `pip3 install -r requirements.txt`.


### Modem Losing Connection  
The modem will drop connection from time to time. Instead of having to pay attention to it, make a cronjob and script to reset it if it's dropped off.
1. Create script called `test-and-connect-modem.sh`.
```bash
#!/bin/bash
FILE=/dev/ttyUSB2

if ! test -c "$FILE"; then
  systemctl restart eg25-manager
fi
```
2. Set privileges and ownership of script `sudo chown root:root test-and-connect-modem.sh
 && sudo chmod 700 test-and-connect-modem.sh`.
3. Enable cron to run every minute via `sudo crontab -e` and add `* * * * * /home/alarm/test-and-connect-modem.sh`.


### MMS (Receiving)  
0. Install PulseAudio (already done in Bluetooth Audio Setup section).
1. Install `recoverjpeg` via [https://aur.archlinux.org/packages/recoverjpeg/](https://aur.archlinux.org/packages/recoverjpeg/)
  1. Clone with `git clone https://aur.archlinux.org/recoverjpeg.git`.
  2. Make the package via `cd ./recoverjpeg && makepkg -A`.
  3. Install via  `sudo pacman -S *.gz`
2. Download the [mms polling script](https://github.com/d0n601/PinePhone/blob/main/mms.sh) called `mms.sh` (modify as needed if you're not using Arch).
3. Set privileges and ownership of script `sudo chown root:root mms.sh
 && sudo chmod 700 mms.sh`.
3. Enable cron to run every minute via `sudo crontab -e` and add `* * * * * /home/alarm/mms.sh`.



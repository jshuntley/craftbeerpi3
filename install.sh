#!/bin/bash
#CraftBeerPi Installer
# Copy 2017 Manuel Fritsch

confirmAnswer () {
whiptail --title "Confirmation" --yes-button "Yes" --no-button "No"  --defaultno --yesno "$1" 10 56
return $?
}

show_menu () {
   # We show the host name right in the menu title so we know which Pi we are connected to
   OPTION=$(whiptail --title "CraftBeerPi 3.0" --menu "Choose your option:" 15 56 7 \
   "1" "Install CraftBeerPi" \
   "2" "Clear Database" \
   "3" "Add To Autostart" \
   "4" "Remove From Autostart" \
   "5" "Start CraftBeerPi" \
   "6" "Stop CraftBeerPi" \
   "7" "Software Update (git pull)" \
   "8" "Reset File Changes (git reset --hard)" \
   "9" "Clear all logs" \
   "10" "Reboot Raspberry Pi" \
   "11" "Stop CraftBeerPi, Clear logs, Start CraftBeerPi" 3>&1 1>&2 2>&3 \
   "12" "Uninstall CraftBeerPi")

   BUTTON=$?
   # Exit if user pressed cancel or escape
   if [[ ($BUTTON -eq 1) || ($BUTTON -eq 255) ]]; then
       exit 1
   fi
   if [ $BUTTON -eq 0 ]; then
       case $OPTION in
       1)
           confirmAnswer "Would you like run apt-get update & apt-get upgrade?"
           if [ $? = 0 ]; then
             apt-get -y update; apt-get -y upgrade;
           fi

#           apt-get -y install python-setuptools
           apt-get -y install python3-pip python3-dev python3-rpi.gpio
           apt-get -y install libpcre3-dev git
           pip3 install -r requirements.txt

           confirmAnswer "Would you like to add active 1-wire support at your Raspberry PI now? IMPORTANT: The 1-wire thermometer must be conneted to GPIO 4!"
           if [ $? = 0 ]; then
             #apt-get -y update; apt-get -y upgrade;
             echo '# CraftBeerPi 1-wire support' >> "/boot/config.txt"
             echo 'dtoverlay=w1-gpio,gpiopin=4,pullup=on' >> "/boot/config.txt"

           fi

           sudo mv ./config/splash.png /usr/share/plymouth/themes/pix/splash.png

           sudo sed "s|#DIR#|${PWD}|g" config/cbpi.service > /etc/systemd/system/cbpi.service
           sudo systemctl daemon-reload
           whiptail --title "Installition Finished" --msgbox "CraftBeerPi installation finished! Press OK to continue." 8 78
           show_menu
           ;;
       2)
          confirmAnswer "Are you sure you want to clear CraftBeerPi? All hardware settings will be deleted."
          if [ $? = 0 ]; then
            sudo rm -f craftbeerpi.db
            whiptail --title "Database Deleted" --msgbox "The CraftBeerPi database was succesfully deleted. You must hit OK to continue." 8 78
            show_menu
          else
           show_menu
          fi
          ;;
       3)
           confirmAnswer "Are you sure you want to add CraftBeerPi to autostart?"
           if [ $? = 0 ]; then            
            sudo systemctl enable cbpi
             whiptail --title "Success!" --msgbox "The CraftBeerPi was added to autostart succesfully. You must hit OK to continue." 8 78
             show_menu
           else
            show_menu
           fi
           ;;
       4)
           confirmAnswer "Are you sure you want to remove CraftBeerPi from autostart?"
           if [ $? = 0 ]; then
               sudo systemctl disable cbpi
               show_menu
           else
               show_menu
           fi
           ;;
       5)
           sudo systemctl start cbpi
           ipaddr=`hostname -I | awk '{print $1}'`
           whiptail --title "CraftBeerPi started" --msgbox "Please connect via Browser: http://$ipaddr:5000" 8 78
           show_menu
           ;;
       6)
           sudo systemctl stop cbpi
           whiptail --title "CraftBeerPi stopped" --msgbox "The software is stopped." 8 78
           show_menu
            ;;
       7)
           confirmAnswer "Are you sure you want to pull a software update?"
           if [ $? = 0 ]; then

             whiptail --textbox /dev/stdin 20 50 <<<"$(git pull)"
             show_menu
           else
              show_menu
           fi
           ;;
        8)
           confirmAnswer "Are you sure you want to reset all file changes for this git respository (git reset --hard)?"
           if [ $? = 0 ]; then
              whiptail --textbox /dev/stdin 20 50 <<<"$(git reset --hard)"
              show_menu
            else
              show_menu
            fi
            ;;
        9)
           confirmAnswer "Are you sure you want to delete all CraftBeerPi log files"
           if [ $? = 0 ]; then
              sudo rm -rf logs/*.log
              whiptail --title "Log files deleted" --msgbox "All CraftBeerPi Files are deleted. You must hit OK to continue." 8 78
              show_menu
           else
              show_menu
           fi
           ;;
        10)
            confirmAnswer "Are you sure you want to reboot the Raspberry Pi?"
            if [ $? = 0 ]; then
              sudo reboot
            else
              show_menu
            fi
            ;;
        11)
            confirmAnswer "Are you sure you want to reboot CraftBeerPi and delete all log files?"
            if [ $? = 0 ]; then
              sudo /etc/init.d/craftbeerpiboot stop
	      sudo rm -rf logs/*.log
	      sudo /etc/init.d/craftbeerpiboot start
	      show_menu
            else
              show_menu
            fi
            ;;
        12)
            confirmAnswer "Are you sure you want to uninstall CraftBeerPi?"
            if [ $? = 0 ]; then
              sudo systemctl stop cbpi
              sudo rm -f /etc/systemd/system/cbpi.service
              whiptail --title "Uninstalled" --msgbox "CraftBeerPi was uninstalled. Press OK to continue." 8 78
              show_menu
            else
              show_menu
            fi
            ;;
       esac
   fi
}

if [ "$EUID" -ne 0 ]
  then whiptail --title "Please run as super user (sudo)" --msgbox "Please run the install file -> sudo install.sh " 8 78
  exit
fi

show_menu

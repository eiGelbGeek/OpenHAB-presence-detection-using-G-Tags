#!/bin/bash

###########################################
# Openhab presence detection using G-Tags #
#                             version 0.1 #
#                 copyright by eiGelbGeek #
###########################################

echo "###########################################"
echo "# Openhab presence detection using G-Tags #"
echo "#                             version 0.1 #"
echo "#                 copyright by eiGelbGeek #"
echo "###########################################"
echo ":::"
echo ":::"
echo "::: Configuration -> Openhab presence detection using G-Tags!"
echo ":::"
echo "::: Keep the spelling as in the displayed examples!"
echo "::: Keep order of the G-Tag IDs / OpenHAB items!"
echo ":::"
echo ":::"
read -p "Enter OpenHAB IP Address e.g. 192.168.2.100:" oh_ip
read -p "Enter OpenHAB RestAPI Port e.g. 8080:" oh_port
read -p "Enter Openhab Item to prevent actions at startup e.g. Presence_Start_Up:" oh_start_up
read -p "Enter G-Tag IDs e.g. "'"7C:3F:50:34:F2:6W" "7C:3F:50:99:XY:09"'":" gtags
read -p "Enter OpenHAB Items for G-Tags e.g. "'"GTag_1" "GTag_2"'":" oh_items

#Update / Install
apt-get -y update
apt-get -y upgrade
apt-get -y install bluez jq

#Create folder
mkdir /usr/local/gtag_presence/

#Create Script
>/usr/local/gtag_presence/scan_gtag.sh
cat <<EOF > /usr/local/gtag_presence/scan_gtag.sh
#!/bin/bash

###########################################
# Openhab presence detection using G-Tags #
#                             version 0.1 #
#                 copyright by eiGelbGeek #
###########################################

#configuration
openhab_url="$oh_ip"
openhab_port="$oh_port"
gtag_ids=($gtags)
openhab_items=($oh_items)
openhab_start_up_item=($oh_start_up)
EOF

cat <<'EOF' >> /usr/local/gtag_presence/scan_gtag.sh
#From here changes can lead to loss of function!
presence_start_up_state="$(curl -X GET --header "Accept: application/json" "http://$openhab_url:$openhab_port/rest/items/$oh_start_up" | jq -r '.state')"

if [ $presence_start_up_state == "OFF" ]; then
  filename=/tmp/bluetooth_devices.$$
  hcitool lescan > $filename & sleep 10
  pkill --signal SIGINT hcitool
  sleep 1

  for ((i=0;i<${#gtag_ids[@]};++i)); do
    searchresult=$(grep -c ${gtag_ids[i]} $filename)
    current_state="$(curl -X GET --header "Accept: application/json" "http://$openhab_url:$openhab_port/rest/items/${openhab_items[i]}" | jq -r '.state')"
    if [ $searchresult -gt 0 ]; then
      if [ $current_state == "OFF" ]; then
        curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "ON" "http://$openhab_url:$openhab_port/rest/items/${openhab_items[i]}"
      fi
    else
      if [ $current_state == "ON" ]; then
        curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "OFF" "http://$openhab_url:$openhab_port/rest/items/${openhab_items[i]}"
      fi
    fi
  done
  rm $filename
fi
EOF

#Create Crontab
crontab -l > gtag_cronjob
echo "*/1 * * * * bash /usr/local/gtag_presence/scan_gtag.sh > /dev/null 2>&1" >> gtag_cronjob
crontab gtag_cronjob
rm gtag_cronjob

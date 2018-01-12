#!/bin/bash

echo "###########################################"
echo "# Openhab presence detection using G-Tags #"
echo "#                             version 0.1 #"
echo "#                 copyright by eiGelbGeek #"
echo "###########################################"
echo ":::"
echo ":::"
echo "::: Konfiguration -> Openhab presence detection using G-Tags!"
echo ":::"
echo "::: Scheibweise wie ich den Beispielen einhalten!"
echo "::: Reihenfolge von Gtag IDs und OpenHAB Items einhalten!"
echo ":::"
echo ":::"
read -p "OpenHAB IP-Adresse eingeben z.B. 192.168.2.100:" oh_ip
read -p "OpenHAB RestAPI Port eingeben z.B. 8080:" oh_port
read -p "G-Tag IDs eingeben z.B. "'"7C:3F:50:34:F2:6W" "7C:3F:50:99:XY:09"'":" gtags
read -p "OpenHAB IP-Adresse eingeben z.B. "'"GTag_1" "GTag_2"'":" oh_items

###########################################
# Openhab presence detection using G-Tags #
#                             version 0.1 #
#                 copyright by eiGelbGeek #
###########################################

#Update / Install
apt-get -y update
apt-get -y upgrade
apt-get -y install bluez

#Ordner erstellen
sudo mkdir /usr/local/gtag_presence/

#Script ertsellen
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
EOF

cat <<'EOF' >> /usr/local/gtag_presence/scan_gtag.sh
#From here changes can lead to loss of function!
filename=/tmp/bluetooth_devices.$$
hcitool lescan > $filename & sleep 10
pkill --signal SIGINT hcitool
sleep 1

for ((i=0;i<${#gtag_ids[@]};++i)); do
  searchresult=$(grep -c ${gtag_ids[i]} $filename)
  if [ $searchresult -gt 0 ]; then
    curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "ON" "http://$openhab_url:$openhab_port/rest/items/${openhab_items[i]}"
  else
    curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "OFF" "http://$openhab_url:$openhab_port/rest/items/${openhab_items[i]}"
  fi
done

rm $filename
EOF

#Crontab erstellen
crontab -l > gtag_cronjob
echo "*/1 * * * * bash /usr/local/gtag_presence/scan_gtag.sh > /dev/null 2>&1" >> gtag_cronjob
crontab gtag_cronjob
rm gtag_cronjob

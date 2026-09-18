# DVMega_Firmware_Update
## Script to update DVMega Firmware on Raspberry Pi

## Background
I recently purchased second hand a Raspberry Pi 3B+ Rev 1.3 with a DVMEGA Raspberry Pi Singleband module for running Pi-Star.  The firmware on the DVMEGA was outdated and I wanted to update to the latest 3.26 version.

I came across these instructions written by KE0FHS that build upon contributions by ON4TOP & G0WFV, and adopted by MW0MWZ: [3 Pi Star Firmware Updates](https://fkarc.net/files/Amateur%20Radio%20Notes/3-Pi-Star_firmware_updates.pdf)

The DVMEGA firmware is available here: [DVMEGA Downloads](https://www.dvmega.nl/Downloads/)

Starting at 8b, I followed the procedure to add the jumper wire, download the files and ran the script, but the script kept returning this error:

```
avrdude stk500_getsync() ... not in sync: resp=0x00
avrdude main() error: unable to open programmer arduino on port /dev/ttyAMA0
```

Troubleshooting the error with AI eventually led to discovering that the script was not actually triggering GPIO Pin 7.  
Pi-Star's GPIO mapping is using legacy sysfs global GPIO numbering, which in this case should be GPIO516.

I vibe coded, and With edited commands, was able to successfully upgrade the firmware to V3.26.


### I hope the flash_dvmega_gpio516.sh script in this repo can help others who run into the same issue.
### 73, de K9FRO


<br>

## Here are the revised steps to complete the firmware upgrade:

### USE AT YOUR OWN RISK!!!


### 1. For updating the DVMEGA firmware on a Raspberry Pi 3, solder a jumper wire between the ATMEGA reset pin and GPIO Header Pin 7.
### 2. SSH into your PiStar 
### 3. Change directory to /tmp
```
cd /tmp
```
### 4. Download the desired DVMEGA firmware file from the DVMEGA Downloads page linked above
```
wget --tries=3 http://www.dvmega.nl/wp-content/uploads/2018/11/DVMEGA_RH_V###_UNO.zip
```
### 5. Unzip the firmware files to the dvmega directory
```
unzip -j -d dvmega DVMEGA_RH_V###_UNO.zip
```
### 6. Change directory to dvmega
```
cd dvmega/
```
### 7. Delete the unneeded .hex file (Japan)
```
rm DVMEGA_RH_V###_UNO_JAPAN.hex
```
### 8. Download the firmware update script to the dvmega folder
```
wget --tries=3 https://raw.githubusercontent.com/K9FRO/pistar-dvmega-firmware-updater/refs/heads/master/flash_dvmega_gpio516.sh
```
### 9. Make the script executable
```
chmod +x flash_dvmega_gpio516.sh
```
### 10. Run the script
```
sudo ./flash_dvmega_gpio516.sh DVMEGA_RH_V###_UNO.hex 
```
### 11. When the script is finished you should see:
```
Firmware flash and explicit verification completed successfully.
Reboot Pi-Star before returning to normal operation.
```
### 12. Reboot the PiStar Machine
```
sudo reboot
```
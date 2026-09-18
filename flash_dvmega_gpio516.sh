#!/usr/bin/env bash
# Flash DVMEGA firmware on this Pi-Star system.
# Reset wire: DVMEGA ATmega RESET -> physical Raspberry Pi header pin 7 (BCM GPIO4).
# On this system's legacy sysfs GPIO mapping, BCM GPIO4 is gpio516.
#
# Usage:
#   sudo ./flash_dvmega_gpio516.sh /full/path/to/firmware.hex
#
# Example:
#   sudo ./flash_dvmega_gpio516.sh /tmp/dvmega/DVMEGA_RH_V326_UNO.hex
#
# Tested on:
# - Pi-Star version: 4.3.8
# - Raspberry Pi model: 3b+ Rev 1.3
# - DVMEGA model: BlueDV-MMDVMhost for Raspberry Pi v1.1 Singleband
# - Physical Pin 7 = BCM GPI04
# - Expected legacy sysfs GPIO = 516 (when GPIO controller base is 512)
# - GPIO mapping: BCM GPIO4 -> sysfs GPIO516
# - UART: /dev/ttyAMA0
# - AVRDUDE baud rate: 115200

set -euo pipefail

# GPIO Configuration
BCM_GPIO=4
EXPECTED_BASE=512
EXPECTED_GPIO=516
GPIO="${EXPECTED_GPIO}"
GPIO_DIR="/sys/class/gpio/gpio${GPIO}"

UART="/dev/ttyAMA0"
FIRMWARE="${1:-}"

GPIOCHIP="/sys/class/gpio/gpiochip${EXPECTED_BASE}"

if [[ ! -d "${GPIOCHIP}" ]]; then
    echo "ERROR: Expected GPIO controller not found: ${GPIOCHIP}"
    exit 1
fi

GPIO_BASE=$(cat "${GPIOCHIP}/base")
GPIO_LABEL=$(cat "${GPIOCHIP}/label")

CALCULATED_GPIO=$((GPIO_BASE + BCM_GPIO))

if [[ "${GPIO_BASE}" -ne "${EXPECTED_BASE}" ]]; then
    echo "ERROR: Unexpected GPIO base: ${GPIO_BASE}"
    exit 1
fi

if [[ "${CALCULATED_GPIO}" -ne "${EXPECTED_GPIO}" ]]; then
    echo "ERROR: Unexpected GPIO mapping."
    echo "Expected GPIO${EXPECTED_GPIO}, calculated GPIO${CALCULATED_GPIO}."
    exit 1
fi

echo "GPIO mapping verified:"
echo "  Controller: ${GPIO_LABEL}"
echo "  Base: ${GPIO_BASE}"
echo "  BCM GPIO: ${BCM_GPIO}"
echo "  Legacy sysfs GPIO: ${CALCULATED_GPIO}"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script with sudo."
    exit 1
fi

if [[ -z "${FIRMWARE}" ]]; then
    echo "Usage: sudo $0 /full/path/to/firmware.hex"
    exit 1
fi

if [[ ! -f "${FIRMWARE}" ]]; then
    echo "Firmware file not found: ${FIRMWARE}"
    exit 1
fi

if [[ ! -c "${UART}" ]]; then
    echo "UART device not found: ${UART}"
    exit 1
fi

release_reset() {
    if [[ -e "${GPIO_DIR}/value" ]]; then
        echo 1 > "${GPIO_DIR}/value" || true
    fi
}
trap release_reset EXIT INT TERM

systemctl stop pistar-watchdog.timer dstarrepeater.timer mmdvmhost.timer || true
systemctl stop pistar-watchdog.service dstarrepeater.service mmdvmhost.service || true

if [[ ! -d "${GPIO_DIR}" ]]; then
    echo "Exporting GPIO${GPIO}..."
    echo "${GPIO}" > /sys/class/gpio/export
    sleep 0.1
fi

if [[ ! -d "${GPIO_DIR}" ]]; then
    echo "ERROR: GPIO${GPIO} could not be exported."
    exit 1
fi

if [[ ! -e "${GPIO_DIR}/direction" ]]; then
    echo "ERROR: GPIO${GPIO} direction interface unavailable."
    exit 1
fi

if [[ ! -e "${GPIO_DIR}/value" ]]; then
    echo "ERROR: GPIO${GPIO} value interface unavailable."
    exit 1
fi

echo out > "${GPIO_DIR}/direction"
echo 1 > "${GPIO_DIR}/value"

echo "Flashing firmware: ${FIRMWARE}"
echo "Pulsing DVMEGA reset on physical pin 7 (sysfs GPIO${GPIO})..."
echo 0 > "${GPIO_DIR}/value"
sleep 0.2
echo 1 > "${GPIO_DIR}/value"

/usr/bin/avrdude \
    -p m328p \
    -c arduino \
    -P "${UART}" \
    -b 115200 \
    -F \
    -U "flash:w:${FIRMWARE}" \
    -v

echo ""
echo "Firmware flash and explicit verification completed successfully."
echo "Reboot Pi-Star before returning to normal operation."
echo ""

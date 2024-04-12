#!/bin/bash

# Constants
RULES_FILE="99-xboxcontroller.rules"
UDEV_RULES_DIR="/etc/udev/rules.d/"
FILE=$UDEV_RULES_DIR$RULES_FILE
SUDO=''

if [ "$EUID" -ne 0 ]; then
  SUDO='sudo'
fi

if [ -f $FILE ]; then
  echo "ERROR: $FILE already exists."
  echo "ABORTING";
else
  echo "Copying $RULES_FILE to $UDEV_RULES_DIR"
  $SUDO cp $RULES_FILE $FILE

  echo "Reloading UDEV Rules"
  $SUDO udevadm control --reload-rules

  echo "Triggering UDEV Rules"
  $SUDO udevadm trigger
fi


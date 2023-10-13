#!/bin/bash

# Define the source directory on the Android device
SRC_DIR="/storage/emulated/0/DCIM/Camera"

# Define the destination directory on your Linux machine
DEST_DIR="$HOME/Pictures/OnePlus"

# Wildcard for targetting specific files. E.g. *.jpg
WILDCARD=""

# Define log file
LOG_FILE="$DEST_DIR/copy.log"


# function to print message to stderr and stdout
# and save message in the log file
log_error() {
	local message="$1"
	printf "Error: $message\n" >&2
	printf "Error: $message\n" >> $LOG_FILE
}

# Create destination directory if it doesn't exist, and check if it is writable
if [ ! -d "$DEST_DIR" ]; then
	if mkdir -p "$DEST_DIR"; then
		printf "Destination directory created: $DEST_DIR\n"
	else
		log_error "Error: Could not create destination directory: $DEST_DIR"
		exit 1
	fi
fi

if [ ! -w "$DEST_DIR" ]; then
	log_error "Error: Destination directory is not writable: $DEST_DIR"
	exit 1
fi

# create a log file if not in the destination directory
if [ ! -e "$LOG_FILE" ]; then
	touch "$LOG_FILE"
fi

# Check if log file is writable
if [ ! -w "$LOG_FILE" ]; then
	log_error "Error: Log file is not writable: $LOG_FILE"
	exit 1
fi

# Initialize counters
copied=0
skipped=0
errors=0

# List files in the source directory, apply wildcard filtering
file_list_raw=$(adb shell "find $SRC_DIR/$WILDCARD -type f")
if [ $? -ne 0 ]; then
	exit 1
fi

# Remove the carriage returns
file_list=$(echo "$file_list_raw" | tr -d '\r')

# Log the date
currentDate=`date +"%d.%m.%Y %T"`
printf "_______ Copy from $currentDate _______\n" >> $LOG_FILE

printf "Copying files from $SRC_DIR to $DEST_DIR\n"

# iterate through file list
for file in $file_list; do
	# Extract the file name without the path
	filename=$(basename "$file")
	
	# Check if file exists in the destination directory
	if [ ! -e "$DEST_DIR/$filename" ]; then
		# File does not exist in the destination, copy it
		printf "Copying $filename\033[0K\r"
		adb pull -a "$file" "$DEST_DIR" > /dev/null 2>> $LOG_FILE
		if [ $? -ne 0 ]; then
			errors=$((errors+1))
		else
			printf "Copied: $filename\n" >> $LOG_FILE
			copied=$((copied+1))
		fi
	else
		# File already exists in destination, skip it
		printf "Skipping $filename\033[0K\r"
		skipped=$((skipped+1))
	fi
done

printf "Copied $copied\nSkipped $skipped\nErrors: $errors\n" >> $LOG_FILE

printf "\033[0K\r"
printf "DONE\nCopied: $copied\nSkipped: $skipped\nErrors: $errors\033[0K\r\n"



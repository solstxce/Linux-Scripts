#!/bin/bash

# ✅ Usage check
if [ $# -ne 2 ]; then
    echo "Usage: $0 <start_hex> <end_hex>"
    echo "Example: $0 20 7f"
    exit 1
fi

# 🎨 Colors & Icons
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"
CHECK="✅"
ARROW="➡️"
FOLDER="📂"
PACKAGE="📦"
TRASH="🗑️"

# 📌 Base path on device
BASE_PATH="/storage/emulated/0/Download/Cricket 24/data"

start_hex=$1
end_hex=$2

echo -e "${BLUE}🚀 Starting adb pulls from ${start_hex} to ${end_hex}...${RESET}"

current_tens=""
group_folders=()

for i in $(seq 0x$start_hex 0x$end_hex); do
    folder=$(printf "%02x" $i)   # two-digit hex
    tens="${folder:0:1}"         # first hex digit

    # If tens place changed (new group starting)
    if [[ "$current_tens" != "" && "$tens" != "$current_tens" ]]; then
        tar_file="${current_tens}.tgz"
        echo -e "${BLUE}${PACKAGE} Creating archive: ${tar_file}...${RESET}"
        tar czf "$tar_file" "${group_folders[@]}" && \
        echo -e "${GREEN}${CHECK} Packed into ${tar_file}${RESET}" || \
        echo -e "${RED}❌ Failed to create ${tar_file}${RESET}"

        echo -e "${YELLOW}${TRASH} Deleting source folders: ${group_folders[*]}${RESET}"
        rm -rf "${group_folders[@]}"

        group_folders=()
    fi

    echo -e "${YELLOW}${ARROW} Pulling ${FOLDER} ${folder}...${RESET}"
    adb pull "${BASE_PATH}/${folder}" "./${folder}" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECK} Successfully pulled ${folder}${RESET}"
        group_folders+=("${folder}")
    else
        echo -e "${RED}❌ Failed to pull ${folder}${RESET}"
    fi

    current_tens=$tens
    sleep 1
done

# Final group tar + delete
if [[ ${#group_folders[@]} -gt 0 ]]; then
    tar_file="${current_tens}.tgz"
    echo -e "${BLUE}${PACKAGE} Creating archive: ${tar_file}...${RESET}"
    tar czf "$tar_file" "${group_folders[@]}" && \
    echo -e "${GREEN}${CHECK} Packed into ${tar_file}${RESET}" || \
    echo -e "${RED}❌ Failed to create ${tar_file}${RESET}"

    echo -e "${YELLOW}${TRASH} Deleting source folders: ${group_folders[*]}${RESET}"
    rm -rf "${group_folders[@]}"
fi

echo -e "${BLUE}✨ All pulls + packaging finished (${start_hex} → ${end_hex})!${RESET}"

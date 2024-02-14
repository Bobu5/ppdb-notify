#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Config

# Set the Webhook URL
WEBHOOK="https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# Set the array of no_daftar IDs to check
NO_DAFTAR_IDS=("xxxxxxxxxxxxxxx" "xxxxxxxxxxxxxxx" "xxxxxxxxxxxxxxx")
# Set the URL base for fetching the JSON data
API_URL_BASE="https://api-jtg.siap-ppdb.com/cari?no_daftar="
# Set the path to store the previous data for each ID
PREVIOUS_DATA_DIR="${SCRIPT_DIR}/prev-data"
mkdir -p "$PREVIOUS_DATA_DIR"  # Create the directory if it doesn't exist

####################

# Function to fetch the desired data from the JSON
get_data() {
    local id="$1"
    local api_url="${API_URL_BASE}${id}"
    local api_response=$(curl -s "$api_url")
    local name=$(echo "$api_response" | jq -r '.[0][3][2][3]')
    local queue=$(echo "$api_response" | jq -r '.[11][3][2][4]')
    local limit=$(echo "$api_response" | jq -r '.[11][3][2][5]')
    local regtype=$(echo "$api_response" | jq -r '.[9][3][2][3]')
    local school=$(echo "$api_response" | jq -r '.[9][3][4][3]')
    echo "$name" > "$PREVIOUS_DATA_DIR/${id}_data.txt"
    echo "$queue" >> "$PREVIOUS_DATA_DIR/${id}_data.txt"
    echo "$limit" >> "$PREVIOUS_DATA_DIR/${id}_data.txt"
    echo "$regtype" >> "$PREVIOUS_DATA_DIR/${id}_data.txt"
    echo "$id" >> "$PREVIOUS_DATA_DIR/${id}_data.txt"
    echo "$school" >> "$PREVIOUS_DATA_DIR/${id}_data.txt"
}

# Function to compare the current and previous data for an ID
check_data() {
    local id="$1"
    local previous_data_file="${PREVIOUS_DATA_DIR}/${id}_data.txt"

    # Read the previous data for the ID
    if [ -f "$previous_data_file" ]; then
        #read -r previous_nama previous_queue previous_limit previous_id< "$previous_data_file"
        local previous_name=$(sed -n '1p' "$previous_data_file")
        local previous_queue=$(sed -n '2p' "$previous_data_file")
        local previous_limit=$(sed -n '3p' "$previous_data_file")
        local previous_regtype=$(sed -n '4p' "$previous_data_file")
        local previous_id=$(sed -n '5p' "$previous_data_file")
        local previous_school=$(sed -n '6p' "$previous_data_file")
    else
        previous_name=""
        previous_queue=""
        previous_limit=""
        previous_regtype=""
        previous_id=""
        previous_school=""
    fi

    # Fetch the current data for the ID
    get_data "$id"
    local current_name=$(sed -n '1p' "$PREVIOUS_DATA_DIR/${id}_data.txt")
    local current_queue=$(sed -n '2p' "$PREVIOUS_DATA_DIR/${id}_data.txt")
    local current_limit=$(sed -n '3p' "$PREVIOUS_DATA_DIR/${id}_data.txt")
    local current_regtype=$(sed -n '4p' "$previous_data_file")
    local current_id=$(sed -n '5p' "$PREVIOUS_DATA_DIR/${id}_data.txt")
    local current_school=$(sed -n '6p' "$PREVIOUS_DATA_DIR/${id}_data.txt")
    # Compare current and previous datax

    if [ "$previous_queue" = "" ]; then
        update_reason="Queue for \`$current_id\` is null, Is this the first time the user has been added to the script?"
    fi

    # if [ "$current_queue" != "$previous_queue" ] && [ -n "$previous_queue" ]; then
    #     update_reason="Queue for \`$current_id\` has changed"
    # fi

    if [ "$current_queue" != "$previous_queue" ]; then

        bash ${SCRIPT_DIR}/discord.sh \
        --webhook-url=$WEBHOOK \
        --username "SekooritiCatto" \
        --avatar "https://cdn.discordapp.com/avatars/957310262250184734/5df56675d330b1fd95ecce7a0095192e.webp" \
        --title "$current_name" \
        --url "https://ppdb.jatengprov.go.id/#/030001/detail/$current_id"\
        --description "$update_reason"\
        --field "Tujuan;\`$current_school\`;false"\
        --field "Urutan;\`$previous_queue ➔ $current_queue\` dari \`$current_limit\`;true"\
        --field "Jalur;\`$current_regtype\`;true"\
        --color 0x4287f5 \
        --footer "PPDB_Notify by Bobu5"\
        --timestamp 
        #echo "($current_name)[$current_id] -> $current_queue / $current_limit --- $previous_limit"
        
        # --description "($current_name)[] -> $current_queue / $current_limit --- $previous_limit" \
        # echo "Data changed for ID $id -> $nama ($urutan Dari $previous_value)"
        # echo "Name: $nama"
        # echo "Urutan: $urutan"
        # echo "Batas: $batas"
    fi
}

# Loop through each no_daftar ID and check for data changes
for id in "${NO_DAFTAR_IDS[@]}"; do
    check_data "$id"
done

#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Config

# Set the Webhook URL
WEBHOOK="https://discord.com/api/webhooks/xxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# Set the type(s)
## Options: reguler (Zonasi), prestasi, perpindahan, afirmasi
TYPES=("reguler" "prestasi")
# to be filled with schoolid from PPDB Site
SCHOOL_IDS=("1-32030312-0" "1-32030307-0")
# Set the path to store the previous data for each ID
PREVIOUS_DATA_DIR="${SCRIPT_DIR}/prev-data/school"
mkdir -p "$PREVIOUS_DATA_DIR"  # Create the directory if it doesn't exist

####################

# Function to check if the data has changed
has_data_changed() {
    local type=$1
    local school_id=$2
    local data=$3
    local file_path="$PREVIOUS_DATA_DIR/.data_${type}_${school_id}"

    if [ ! -f "$file_path" ]; then
        echo "$data" > "$file_path"
        return 0
    fi

    local previous_data=$(cat "$file_path")
    if [ "$data" != "$previous_data" ]; then
        echo "$data" > "$file_path"
        return 0
    fi

    return 1
}

# Loop through the types and school IDs
for type in "${TYPES[@]}"; do
    for school_id in "${SCHOOL_IDS[@]}"; do
        # Construct the API URL
        api_url="https://ppdb.jatengprov.go.id/seleksi/${type}/sma/${school_id}.json"

        # Fetch data from the API
        api_response=$(curl -s "$api_url")

        # Extract the desired data using jq based on the type
        if [ "$type" = "reguler" ]; then
            data=$(echo "$api_response" | jq -r 'try .data[-1][4] catch ""')
            school_name=$(echo "$api_response" | jq -r 'try .sekolah.nama catch ""')
        elif [ "$type" = "prestasi" ]; then
            data=$(echo "$api_response" | jq -r 'try .data[-1][5] catch ""')
            school_name=$(echo "$api_response" | jq -r 'try .sekolah.nama catch ""')
        else
            data="null"
            school_name="null"
        fi

        # Check if the data has changed
        if has_data_changed "$type" "$school_id" "$data"; then
            # Print the output
            echo "Type: $type, School ID: $school_id"
            echo "Data: $data, School Name: $school_name"
            echo "---------------------------"
            bash ${SCRIPT_DIR}/discord.sh \
            --webhook-url=$WEBHOOK \
            --username "SekooritiCatto" \
            --avatar "https://cdn.discordapp.com/avatars/957310262250184734/5df56675d330b1fd95ecce7a0095192e.webp" \
            --title "Lowest \`$Type\` Value for \`$school_name\`" \
            --url ""\
            --description ""\
            --field "Type; \`$type\`"\
            --field "School ID; \`$school_id\`" \
            --field "Val;\`$data\`;false"\
            --color 0x4287f5 \
            --footer "PPDB_Notify by Bobu5"\
            --timestamp 
        fi
    done
done
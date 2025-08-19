#!/bin/bash

# A script to produce instrumental background music based on length and mood.

# Function to display usage instructions
usage() {
    echo "Usage: $0 \"<duration>, <description>\""
    echo "Example: $0 \"1 minute, Positive and Uplifting (conveying hope, triumph, or optimism)\""
    echo "The duration can be specified in 'minutes' or 'seconds'."
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ] || [ "$1" == "--help" ]; then
    usage
    exit 1
fi

# --- Virtual Environment and Dependency Setup ---
VENV_DIR="venv"

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed. Please install it to use this script."
    echo "On Debian/Ubuntu, you can install it with: sudo apt-get install python3"
    exit 1
fi

# Check for python3-venv package, which is needed to create virtual environments
if ! python3 -c "import venv" &> /dev/null; then
    echo "Error: The 'venv' module is not available for Python 3."
    echo "On Debian/Ubuntu, you can install it with: sudo apt-get install python3-venv"
    exit 1
fi

# Create the virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment in './$VENV_DIR'..."
    if ! python3 -m venv "$VENV_DIR"; then
        echo "Failed to create the virtual environment."
        exit 1
    fi
fi

# Check for required Python packages within the virtual environment
if ! "$VENV_DIR/bin/python3" -c "import torch; import audiocraft" &> /dev/null; then
    echo "Required Python packages not found in the virtual environment."
    echo "Installing torch and audiocraft... (This may take a while)"
    if ! "$VENV_DIR/bin/pip" install torch audiocraft; then
        echo "Failed to install required Python packages."
        exit 1
    fi
fi

# Check if the generator script exists
if [ ! -f "generate_music.py" ]; then
    echo "Error: The 'generate_music.py' script was not found in the current directory."
    exit 1
fi

# --- Input Parsing ---
input_string="$1"

# Separate the duration from the description
duration_part=$(echo "$input_string" | cut -d',' -f1)
description_part=$(echo "$input_string" | cut -d',' -f2-)

# Trim leading/trailing whitespace from the description
description=$(echo "$description_part" | sed 's/^[ \t]*//;s/[ \t]*$//')

if [ -z "$description" ]; then
    echo "Error: The description is missing or the input format is incorrect."
    usage
    exit 1
fi

# Extract the numeric value of the duration
duration_value=$(echo "$duration_part" | grep -o '[0-9]\+')

if [ -z "$duration_value" ]; then
    echo "Error: The duration value is missing or invalid."
    usage
    exit 1
fi

# Convert duration to seconds
duration_seconds=0
if echo "$duration_part" | grep -qi "minute"; then
    duration_seconds=$((duration_value * 60))
elif echo "$duration_part" | grep -qi "second"; then
    duration_seconds=$duration_value
else
    echo "Error: The duration unit (minutes or seconds) is not specified."
    usage
    exit 1
fi

# --- Music Generation ---
# Create a sanitized filename from the description
sanitized_description=$(echo "$description" | tr -s ' ' '_' | tr -cd '[:alnum:]_-')
output_filename="${sanitized_description}.wav"

echo "Generating music. This may take a few moments..."
"$VENV_DIR/bin/python3" generate_music.py --description "$description" --duration "$duration_seconds" --output "$output_filename"

if [ $? -eq 0 ]; then
    echo "Successfully generated music and saved it to: $output_filename"
else
    echo "An error occurred during music generation."
fi

# Text-to-Music Generator

This project consists of a set of scripts to generate instrumental background music from a textual description of its mood and a specified duration.

## Description

The main script is `produce_music.sh`, which acts as a user-friendly interface for a Python script (`generate_music.py`) that uses Meta's Audiocraft library to generate music.

The script automatically creates and manages a Python virtual environment to avoid conflicts with system-wide packages.

## Dependencies

Before you can run the script, you need to have the following dependencies installed on your system:

1.  **Python 3**: The scripts require Python 3. You can check if you have it installed by running `python3 --version`. If not, you can install it on a Debian-based system with:
    ```bash
    sudo apt-get update
    sudo apt-get install python3
    ```

2.  **Python 3 venv module**: This module is required for creating virtual environments. You can install it on a Debian-based system with:
    ```bash
    sudo apt-get install python3-venv
    ```

The script will automatically create a virtual environment in a directory named `venv` and install the required Python libraries (`torch` and `audiocraft`) into it.

**Note**: The first time you run the script, the required Python packages and the MusicGen model will be downloaded. This is a one-time process and may take a few minutes depending on your internet connection.

## Usage

To generate music, you need to run the `produce_music.sh` script with a single argument: a string that contains the duration and the mood of the music, separated by a comma.

First, make the script executable:
```bash
chmod +x produce_music.sh
```

### Syntax

```bash
./produce_music.sh "<duration>, <description>"
```

### Example

To generate a 1-minute-long tune that is "Positive and Uplifting", you would run:

```bash
./produce_music.sh "1 minute, Positive and Uplifting (conveying hope, triumph, or optimism)"
```

The script will then generate a `.wav` file in the same directory, with a name based on the description (e.g., `Positive_and_Uplifting_conveying_hope_triumph_or_optimism.wav`).

## How it Works

The `produce_music.sh` script first checks for the required system dependencies. It then creates a Python virtual environment (if it doesn't already exist) and installs the necessary Python libraries into it. Finally, it parses your input to determine the length and mood and calls the `generate_music.py` script using the virtual environment's Python interpreter. This script uses the `audiocraft` library and the pre-trained "musicgen-small" model to generate the music. The final output is saved as a WAV audio file.

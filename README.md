# Text-to-Music Generator

This project consists of a set of scripts to generate instrumental background music from a textual description of its mood and a specified duration.

## Description

The main script is `produce_music.sh`, which acts as a user-friendly interface for a Python script (`generate_music.py`) that uses Meta's Audiocraft library to generate music.

## Dependencies

Before you can run the script, you need to have the following dependencies installed:

1.  **Python 3**: The scripts are written in Python 3. You can check if you have it installed by running `python3 --version`. If not, you can install it on a Debian-based system with:
    ```bash
    sudo apt-get update
    sudo apt-get install python3
    ```

2.  **pip for Python 3**: This is the package installer for Python. You can install it with:
    ```bash
    sudo apt-get install python3-pip
    ```

3.  **Required Python Libraries**: The script requires the `torch` and `audiocraft` libraries. You can install them using pip:
    ```bash
    pip install torch audiocraft
    ```
    **Note**: The first time you run the script, the MusicGen model will be downloaded. This is a one-time process and may take a few minutes depending on your internet connection.

## Usage

To generate music, you need to run the `produce_music.sh` script with a single argument: a string that contains the duration and the mood of the music, separated by a comma.

The script needs to be made executable first:
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

The `produce_music.sh` script parses your input to determine the length and mood. It then calls the `generate_music.py` script, which uses the `audiocraft` library and the pre-trained "musicgen-small" model to generate the music. The final output is saved as a WAV audio file.

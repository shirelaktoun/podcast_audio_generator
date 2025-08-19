# Text-to-Music Generator (for Windows)

This project provides a PowerShell script to generate instrumental background music from a textual description of its mood and a specified duration. It is designed to be run on Windows 11.

## Description

The main script, `produce_music.ps1`, provides a user-friendly interface in PowerShell. It calls a Python script (`generate_music.py`) in the background, which uses Meta's Audiocraft library to generate the music.

The script is self-contained and will automatically set up a local Python virtual environment to handle all its dependencies, ensuring that it does not interfere with other Python projects or system-wide packages.

## Prerequisites

Before you begin, you need to have Python 3 installed on your Windows 11 system.

1.  **Install Python 3**:
    *   Download the latest Python 3 installer from the official website: `https://www.python.org/downloads/windows/`
    *   Run the installer.
    *   **Important**: On the first page of the installer, make sure to check the box that says **"Add Python to PATH"**. This is crucial for the script to be able to find and use Python.

2.  **PowerShell Execution Policy**:
    *   By default, Windows may prevent you from running local PowerShell scripts. To allow the script to run, you may need to change the execution policy for your user.
    *   Open PowerShell as an Administrator and run the following command:
        ```powershell
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        ```
    *   This only needs to be done once.

## Usage

1.  Open a PowerShell terminal.
2.  Navigate to the directory where you have saved the project files (e.g., `cd C:\path\to\project`).
3.  Run the `produce_music.ps1` script with your desired prompt as an argument.

### Syntax

```powershell
.\produce_music.ps1 "<duration>, <description>"
```

### Example

To generate a 1-minute-long tune that is "Positive and Uplifting", you would run:

```powershell
.\produce_music.ps1 "1 minute, Positive and Uplifting (conveying hope, triumph, or optimism)"
```

### First-Time Setup

The first time you run the script, it will perform a one-time setup:
*   It will create a Python virtual environment in a new `venv` folder.
*   It will download and install the required Python libraries (`audiocraft`, `pytorch`, etc.) into this `venv` folder. This may take several minutes depending on your internet connection.
*   It will also download the pre-trained MusicGen AI model the first time you generate music.

Subsequent runs of the script will be much faster as they will use the already-installed dependencies.

The script will generate a `.wav` file in the same directory, with a name based on the description you provided.

## How it Works

The `produce_music.ps1` script automates the entire process. It checks for Python, sets up the isolated virtual environment, and installs all dependencies. It then parses your input to determine the length and mood, and finally calls the `generate_music.py` script to do the actual work of creating the music with the `audiocraft` library.

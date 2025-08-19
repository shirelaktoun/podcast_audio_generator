<#
.SYNOPSIS
A PowerShell script to produce instrumental background music based on length and mood.

.DESCRIPTION
This script serves as a user-friendly interface for a Python script that generates music.
It handles dependency checks, virtual environment creation, and input parsing.

.PARAMETER Prompt
A string containing the duration and the mood, separated by a comma.
Example: "1 minute, Positive and Uplifting (conveying hope, triumph, or optimism)"

.EXAMPLE
PS> .\produce_music.ps1 "1 minute, a happy and uplifting tune"

This command will generate a one-minute-long WAV file with a happy and uplifting mood.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, HelpMessage="A string containing the duration and mood, e.g., '1 minute, happy and uplifting'")]
    [string]$Prompt
)

# --- Initial Checks ---
$ErrorActionPreference = "Stop"
$ScriptPath = $PSScriptRoot

# Check if Python is installed and available
try {
    $pythonPath = (Get-Command python).Source
    Write-Host "Python found at: $pythonPath"
} catch {
    Write-Error "Python is not installed or not found in your PATH. Please install Python 3 and ensure it is added to your PATH."
    exit 1
}

# Check if the generator script exists
$generatorScript = Join-Path -Path $ScriptPath -ChildPath "generate_music.py"
if (-not (Test-Path $generatorScript)) {
    Write-Error "The 'generate_music.py' script was not found in the same directory as this script."
    exit 1
}

# --- Virtual Environment and Dependency Setup ---
$venvDir = Join-Path -Path $ScriptPath -ChildPath "venv"

if (-not (Test-Path $venvDir)) {
    Write-Host "Creating Python virtual environment in '$venvDir'..."
    try {
        python -m venv $venvDir
        Write-Host "Virtual environment created successfully."
    } catch {
        Write-Error "Failed to create the Python virtual environment. Make sure the 'venv' module is available."
        exit 1
    }
}

$pythonVenvPath = Join-Path -Path $venvDir -ChildPath "Scripts\python.exe"

# Check for required Python packages
try {
    $checkCommand = "& `"$pythonVenvPath`" -c 'import torch; import audiocraft'"
    Invoke-Expression $checkCommand
    Write-Host "Required Python packages are already installed."
} catch {
    Write-Host "Required Python packages not found. Installing dependencies... (This may take a while)"
    try {
        $pipVenvPath = Join-Path -Path $venvDir -ChildPath "Scripts\pip.exe"
        $installCommand = "& `"$pipVenvPath`" install audiocraft --extra-index-url https://download.pytorch.org/whl/cpu"
        Invoke-Expression $installCommand
        Write-Host "Dependencies installed successfully."
    } catch {
        Write-Error "Failed to install required Python packages. Please check your internet connection and try again."
        exit 1
    }
}

# --- Input Parsing ---
$parts = $Prompt.Split(',', 2)
if ($parts.Length -ne 2) {
    Write-Error "Invalid prompt format. Please use the format: '<duration>, <description>'"
    exit 1
}

$durationPart = $parts[0].Trim()
$description = $parts[1].Trim()

$durationSeconds = 0
if ($durationPart -match '(\d+)\s*minute') {
    $durationSeconds = [int]$matches[1] * 60
} elseif ($durationPart -match '(\d+)\s*second') {
    $durationSeconds = [int]$matches[1]
} else {
    Write-Error "Invalid duration format. Please specify the duration in 'minutes' or 'seconds'."
    exit 1
}

if ($durationSeconds -le 0) {
    Write-Error "Duration must be a positive number."
    exit 1
}

# --- Music Generation ---
# Create a sanitized filename
$sanitizedDescription = $description -replace '[^a-zA-Z0-9_-]+', '_' -replace '_+', '_'
$outputFilename = "$sanitizedDescription.wav"
$outputFilePath = Join-Path -Path $ScriptPath -ChildPath $outputFilename

Write-Host "Generating music for the description: '$description' with a duration of $durationSeconds seconds..."

try {
    $generateCommand = "& `"$pythonVenvPath`" `"$generatorScript`" --description `"$description`" --duration $durationSeconds --output `"$outputFilePath`""
    Invoke-Expression $generateCommand
    Write-Host "Successfully generated music and saved it to: $outputFilePath"
} catch {
    Write-Error "An error occurred during music generation. Please see the output from the Python script for details."
    exit 1
}

#!/bin/bash

#
# Title:        Jewels of History Podcast Generator Script
# Description:  Creates a podcast from a text script using Google TTS and ffmpeg,
#               with background music specified in the script itself.
# Author:       Jules & User
#

# --- Rigorous Error Handling ---
# set -euo pipefail # Disabled to bypass a server-specific environment issue.

# --- Configuration ---
ENV_FILE="/home/make-sftp/JH/.env"
INPUT_FILE="/home/make-sftp/JH/incoming/jewel_p1.txt"
OUTPUT_FILE="/home/make-sftp/JH/output/jewel_p1.wav"
DEFAULT_MUSIC="/home/make-sftp/music/bg/history.mp3"
MUSIC_DIR="/home/make-sftp/music/bg"

FAILED_LINES_FILE="$(dirname "$OUTPUT_FILE")/failed_lines.txt"

# --- Global Variables ---
tmp_dir=""
fade_slope=""
processed_section_count=0
final_section_audio_files=()
NO_MUSIC=false
TURKISH=false


# Audio processing settings
INTRO_DURATION=5
FADE_DURATION=3
BACKGROUND_VOLUME=0.1



if [ "$TURKISH" = false ]; then
    # Google Cloud TTS settings ENGLISH
    TTS_API_ENDPOINT="https://eu-texttospeech.googleapis.com/v1/text:synthesize"
    VOICE_DEBORAH="en-GB-Chirp3-HD-Leda"
    VOICE_KIERAN="en-GB-Chirp3-HD-Rasalgethi"
    Lang_Code="en-GB"
else
    # Google Cloud TTS settings TURKISH
    TTS_API_ENDPOINT="https://eu-texttospeech.googleapis.com/v1/text:synthesize"
    VOICE_AZRA="tr-TR-Chirp3-HD-Leda"
    VOICE_BARIS="tr-TR-Chirp3-HD-Rasalgethi"
    Lang_Code="tr-TR"
fi


# --- Helper Functions ---

log() {
    echo >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $@"
}

check_dependencies() {
    for cmd in curl jq ffmpeg ffprobe sox bc gcloud shuf; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR: Required command '$cmd' is not installed."
            exit 1
        fi
    done
}

generate_tts() {
    local text="$1"
    local voice="$2"
    local output_file="$3"
    local json_payload
    if [ "$TURKISH" = false ]; then
        json_payload=$(jq -n --arg text "$text" --arg voice "$voice"         '{"input": {"text": $text}, "voice": {"languageCode": "en-GB", "name": $voice}, "audioConfig": {"audioEncoding": "MP3"}}')
    else
        json_payload=$(jq -n --arg text "$text" --arg voice "$voice"         '{"input": {"text": $text}, "voice": {"languageCode": "tr-TR", "name": $voice}, "audioConfig": {"audioEncoding": "MP3"}}')
    fi
    local response
    response=$(curl -s -X POST         -H "Authorization: Bearer $(gcloud auth application-default print-access-token)"         -H "Content-Type: application/json; charset=utf-8"         -H "X-Goog-User-Project: $GCLOUD_PROJECT"         -d "$json_payload" "$TTS_API_ENDPOINT")
    if echo "$response" | jq -e '.error' > /dev/null; then
        log "ERROR: Google TTS API call failed."
        echo "$response" | jq '.error' >&2
        return 1
    fi
    echo "$response" | jq -r '.audioContent' | base64 --decode > "$output_file"
    log "Successfully saved speech to '$output_file'"
}

# A pure-bash function to trim leading/trailing whitespace.
trim_whitespace() {
    local var="$1"
    shopt -s extglob
    var="${var##+([[:space:]])}"
    var="${var%%+([[:space:]])}"
    shopt -u extglob
    echo "$var"
}

process_section() {
    local bg_music_file="$1"
    local -n lines_ref="$2"

    ((processed_section_count++))
    local section_num=$processed_section_count

    if [ ${#lines_ref[@]} -eq 0 ]; then return; fi

    log "--- Processing Section $section_num ---"
    log "Using background music: $bg_music_file"

    local section_speech_parts=()
    local line_num=0
    for line in "${lines_ref[@]}"; do
        ((line_num++))
        local text voice speaker dialogue
        if [[ "$line" =~ ^([^:]+):(.*)$ ]]; then
            speaker="${BASH_REMATCH[1]}"
            dialogue="${BASH_REMATCH[2]}"

            if [ "$TURKISH" = false ]; then

                case "$speaker" in
                    n|an|ran|eran|ieran|Kieran) voice="$VOICE_KIERAN" ;;
                    h|ah|rah|orah|borah|eborah|Deborah) voice="$VOICE_DEBORAH" ;;
                    *)
                        log "WARNING: L${line_num} in Sec${section_num} has unknown speaker '$speaker'. Skipping."
                        continue
                        ;;
                esac

            else

                case "$speaker" in
                    ş|ış|rış|arış|Barış) voice="$VOICE_BARIS" ;;
                    a|ra|zra|Azra) voice="$VOICE_AZRA" ;;
                    *)
                        log "WARNING: L${line_num} in Sec${section_num} has unknown speaker '$speaker'. Skipping."
                        continue
                        ;;
                esac
            fi

            text=$(trim_whitespace "$dialogue")
            if [[ -z "$text" ]]; then continue; fi

            local speech_part_file="$tmp_dir/section_${section_num}_speech_${line_num}.mp3"
            if ! generate_tts "$text" "$voice" "$speech_part_file"; then
                log "WARNING: Failed to generate speech for line. Writing to failure log."
                echo "$line" >> "$FAILED_LINES_FILE"
                continue
            fi
            section_speech_parts+=("$speech_part_file")
        else
            log "WARNING: L${line_num} in Sec${section_num} is not in 'Speaker: Dialogue' format. Skipping."
        fi
    done

    if [ ${#section_speech_parts[@]} -eq 0 ]; then
        log "WARNING: No speech was generated for section $section_num. Skipping."
        return
    fi

    local concatenated_speech_file="$tmp_dir/section_${section_num}_full_speech.mp3"
    sox "${section_speech_parts[@]}" "$concatenated_speech_file"

    local section_output_file="$tmp_dir/section_${section_num}_final.wav"

    if [ "$NO_MUSIC" = true ]; then
        log "Section $section_num: Generating speech-only audio."
        ffmpeg -y -v error -i "$concatenated_speech_file" "$section_output_file"
    else
        log "Section $section_num: Mixing speech with background audio."
        local speech_duration
        speech_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$concatenated_speech_file")
        local speech_delay_s=$((INTRO_DURATION + FADE_DURATION))
        local speech_delay_ms=$((speech_delay_s * 1000))
        local total_duration
        total_duration=$(echo "$speech_duration + $speech_delay_s" | bc -l)

        ffmpeg -y -v error -i "$concatenated_speech_file" -stream_loop -1 -i "$bg_music_file" \
-filter_complex \
"[1:a]volume=eval=frame:volume='if(lt(t,${INTRO_DURATION}),1,if(lt(t,${speech_delay_s}),1-((t-${INTRO_DURATION})*${fade_slope}),${BACKGROUND_VOLUME}))'[bg]; [0:a]adelay=${speech_delay_ms}|${speech_delay_ms}[fg]; [bg][fg]amix=inputs=2:duration=longest" \
-t "$total_duration" "$section_output_file"
    fi

    final_section_audio_files+=("$section_output_file")
}

# --- Main Script Logic ---

main() {
    if [[ "$1" == "--no-music" ]]; then
        NO_MUSIC=true
        OUTPUT_FILE="/home/make-sftp/JH/output/Paris_speech_only.wav"
        log "Running in --no-music mode. Background audio will be omitted."
        log "Output will be saved to $OUTPUT_FILE"
    fi

    check_dependencies

    if [ ! -f "$ENV_FILE" ]; then log "ERROR: Env file not found: '$ENV_FILE'"; exit 1; fi
    source "$ENV_FILE"
    : "${GCLOUD_PROJECT?ERROR: GCLOUD_PROJECT not set}"
    : "${GOOGLE_APPLICATION_CREDENTIALS?ERROR: GOOGLE_APPLICATION_CREDENTIALS not set}"
    if [ ! -f "$INPUT_FILE" ]; then log "ERROR: Input file not found: '$INPUT_FILE'"; exit 1; fi

    mkdir -p "$(dirname "$OUTPUT_FILE")"
    rm -f "$FAILED_LINES_FILE"

    tmp_dir=$(mktemp -d -t podcast_generator_XXXXXX)
    trap "log 'Cleaning up temporary directory...'; rm -rf -- '$tmp_dir'" EXIT

    fade_slope=$(echo "(1 - $BACKGROUND_VOLUME) / $FADE_DURATION" | bc -l)

    local current_bg_music="$DEFAULT_MUSIC"
    local current_section_lines=()

    while IFS= read -r line; do
        line=$(trim_whitespace "$line")
        if [[ "$line" =~ ^\[Background\ music\ -\ ([0-9]+)\.mp3\]$ ]]; then
            local music_folder_num="${BASH_REMATCH[1]}"
            # Process the section we've collected so far
            process_section "$current_bg_music" "current_section_lines"

            # Start a new section
            current_section_lines=()
            local music_folder="$MUSIC_DIR/$music_folder_num"

            if [ -d "$music_folder" ]; then
                local next_music_file
                # Find a random mp3 file in the specified folder.
                next_music_file=$(find "$music_folder" -maxdepth 1 -type f -name "*.mp3" 2>/dev/null | shuf -n 1)

                if [ -n "$next_music_file" ]; then
                    current_bg_music="$next_music_file"
                    log "Selected random background music: $current_bg_music"
                else
                    log "WARNING: No .mp3 files found in '$music_folder'. Using default."
                    current_bg_music="$DEFAULT_MUSIC"
                fi
            else
                log "WARNING: Music folder not found: '$music_folder'. Using default."
                current_bg_music="$DEFAULT_MUSIC"
            fi
        else
            # Add dialogue line to the current section
            if [[ -n "$line" ]]; then
                current_section_lines+=("$line")
            fi
        fi
    done < "$INPUT_FILE"

    process_section "$current_bg_music" "current_section_lines"

    if [ ${#final_section_audio_files[@]} -eq 0 ]; then
        log "ERROR: No audio sections were successfully processed."
        exit 1
    fi

    log "Concatenating all processed sections into final output..."
    local concat_list_file="$tmp_dir/concat_list.txt"
    for f in "${final_section_audio_files[@]}"; do
        echo "file '$f'" >> "$concat_list_file"
    done
    ffmpeg -y -v error -f concat -safe 0 -i "$concat_list_file" -c copy "$OUTPUT_FILE"

    log "--- SUCCESS ---"
    log "Final podcast audio created at: $OUTPUT_FILE"
    if [ -f "$FAILED_LINES_FILE" ]; then
        log "NOTE: Some lines failed to process. See: $FAILED_LINES_FILE"
    fi
}

main "$@"

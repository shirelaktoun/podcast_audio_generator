import argparse
import torchaudio
from audiocraft.models import MusicGen
from audiocraft.data.audio import audio_write

def main():
    parser = argparse.ArgumentParser(description="Generate music from a textual description.")
    parser.add_argument("--description", type=str, required=True, help="A description of the music to generate.")
    parser.add_argument("--duration", type=int, required=True, help="The duration of the music in seconds.")
    parser.add_argument("--output", type=str, required=True, help="The path to save the generated audio file.")

    args = parser.parse_args()

    print("Loading the MusicGen model...")
    model = MusicGen.get_pretrained('facebook/musicgen-small')

    print(f"Generating music for the description: '{args.description}' with a duration of {args.duration} seconds...")
    model.set_generation_params(duration=args.duration)
    wav = model.generate([args.description])

    print(f"Saving the generated music to {args.output}...")
    for idx, one_wav in enumerate(wav):
        audio_write(f"{args.output}", one_wav.cpu(), model.sample_rate, strategy="loudness", loudness_compressor=True)

    print("Music generation complete.")

if __name__ == "__main__":
    main()

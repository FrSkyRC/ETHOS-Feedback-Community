#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
import codecs
import hashlib
import os
import shutil
import sys
import tempfile
try:
    import sox
except:
    print("You need sox for python: python -m pip install sox")
    sys.exit(1)
try:
    from google.cloud import texttospeech
except:
    print("You need google text to speech for python: python -m pip install google-cloud-texttospeech")
    sys.exit(1)


def extract_csv(path):
    result = []
    with codecs.open(path, "r", "utf-8") as f:
        reader = csv.reader(f)

        # This skips the first row of the CSV file
        next(reader)
    
        for row in reader:
            if len(row) == 4:
                path, text, options_text, description = row
                options = {}
                for part in options_text.split(";"):
                    if part:
                        key, value = part.split("=")
                        options[key] = value
                result.append((path, text, options, description))
            else:
                print("Invalid row: %s" % row)
    return result


class NullCache:
    def get(self, *args, **kwargs):
        return False
    
    def push(self, *args, **kwargs):
        pass

class PromptsCache:
    def __init__(self, directory):
        self.directory = directory
        if not os.path.exists(directory):
            os.makedirs(directory)

    def path(self, text, options):
        text_hash = hashlib.md5((text + str(options)).encode()).hexdigest()
        return os.path.join(self.directory, text_hash)

    def get(self, filename, text, options):
        cache = self.path(text, options)
        if not os.path.exists(cache):
            return False
        shutil.copy(cache, filename)
        return True

    def push(self, filename, text, options):
        shutil.copy(filename, self.path(text, options))


class BaseGenerator:
    @staticmethod
    def sox(input, output, tempo=None, norm=False, silence=False):
        tfm = sox.Transformer()
        tfm.set_output_format(channels=1, rate=16000, encoding="a-law")
        extra_args = []
        if tempo:
            extra_args.extend(["tempo", str(tempo)])
        if norm:
            extra_args.append("norm")
        if silence:
            extra_args.extend(["reverse", "silence", "1", "0.1", "0.1%", "reverse"])
        tfm.build(input, output, extra_args=extra_args)


class GoogleCloudTextToSpeechGenerator(BaseGenerator):
    def __init__(self, voice, speed):
        self.voice_code = voice
        self.speed = speed
        self.client = texttospeech.TextToSpeechClient()
        self.voice = texttospeech.VoiceSelectionParams(
            language_code="-".join(voice.split("-")[:2]),
            name=voice
        )

    def cache_prefix(self):
        return "google-%s" % self.voice_code

    def build(self, path, text, options):
        print(path, repr(text), options)
        response = self.client.synthesize_speech(
            input=texttospeech.SynthesisInput(text=text),
            voice=self.voice,
            audio_config=texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.LINEAR16,
                sample_rate_hertz=16000,
                speaking_rate=self.speed * float(options.get("speed", 1.0))
            )
        )
        temp_path = tempfile.mkdtemp()
        tts_output = os.path.join(temp_path, "output.wav")
        with open(tts_output, "wb") as out:
            out.write(response.audio_content)
        self.sox(tts_output, path, silence=True)
        shutil.rmtree(temp_path)


def build(engine, voice, speed, csv, cache, only_missing=False, recreate_cache=False):
    if engine == "google":
        generator = GoogleCloudTextToSpeechGenerator(voice, speed)
    else:
        print("Unknown engine %s" % engine)
        return 1

    prompts = extract_csv(csv)
    cache = PromptsCache(os.path.join(cache, generator.cache_prefix())) if cache else NullCache()

    for path, text, options, _ in prompts:
        if only_missing and os.path.exists(path):
            continue
        elif cache and not recreate_cache and cache.get(path, text, options):
            continue
        else:
            generator.build(path, text, options)
            cache.push(path, text, options)

    return 0


def main():
    if sys.version_info < (3, 0, 0):
        print("%s requires Python 3. Terminating." % __file__)
        return 1

    parser = argparse.ArgumentParser(description="Builder for Ethos audio files")
    parser.add_argument('--csv', action="store", help="CSV input file", required=True)
    parser.add_argument('--engine', action="store", help="TTS engine", default="gtts")
    parser.add_argument('--voice', action="store", help="TTS language", required=True)
    parser.add_argument('--cache', action="store", help="TTS files cache")
    parser.add_argument('--recreate-cache', action="store_true", help="Recreate files cache")
    parser.add_argument('--only-missing', action="store_true", help="Generate only missing files")
    parser.add_argument('--speed', type=float, help="Voice speed", default=1.0)
    args = parser.parse_args()

    return build(args.engine, args.voice, args.speed, args.csv, args.cache, args.only_missing, args.recreate_cache)


if __name__ == "__main__":
    exit(main())

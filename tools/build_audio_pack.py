#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
import codecs
import hashlib
import json
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


TOOLS_DIR = os.path.dirname(os.path.realpath(__file__))
AUDIO_DIR = os.path.abspath(os.path.join(TOOLS_DIR, "../audio"))


def extract_csv(path):
    print("Reading CSV file %s..." % path)
    result = []
    filenames = set()
    with codecs.open(path, "r", "utf-8") as f:
        reader = csv.reader(f)

        # This skips the first row of the CSV file
        next(reader)
    
        for i, row in enumerate(reader):
            line = i + 2
            if len(row) == 4:
                path, text, options_text, description = row
                if path.endswith(".wav"):
                    if path not in filenames:
                        options = {}
                        for part in options_text.split(";"):
                            if part:
                                key, value = part.split("=")
                                options[key] = value
                        result.append((path, text, options, description))
                        filenames.add(path)
                    else:
                        print("Line %d: duplicate file %s" % (line, path))
                else:
                    print("Line %d: invalid file %s" % (line, path)    )
            else:
                print("Line %d: invalid format" % line)
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
        text_hash = hashlib.md5((text + str(options)).encode()).hexdigest() + ".wav"
        return os.path.join(self.directory, text_hash)

    def get(self, text, options):
        cache = self.path(text, options)
        return cache if os.path.exists(cache) else None

    def push(self, filename, text, options):
        shutil.copy(filename, self.path(text, options))


def encode(input, output, tempo=None, norm=False, silence=False):
    tfm = sox.Transformer()
    tfm.set_output_format(channels=1, rate=16000, encoding="a-law")
    extra_args = []
    if tempo:
        extra_args.extend(["tempo", str(tempo)])
    if norm:
        extra_args.append("norm")
    if silence:
        extra_args.extend(silence)
    if os.path.exists(output):
        os.unlink(output)
    tfm.build(input, output, extra_args=extra_args)


class GoogleCloudTextToSpeechGenerator:
    def __init__(self, voice, speed):
        self.voice_code = voice
        self.speed = speed
        self.client = texttospeech.TextToSpeechClient()
        self.voice = texttospeech.VoiceSelectionParams(
            language_code="-".join(voice.split("-")[:2]),
            name=voice
        )

    def cache_prefix(self):
        return "google-%s-%r" % (self.voice_code, self.speed)

    def build(self, path, text, options):
        print("  Google TTS:", repr(text))
        if os.path.exists(path):
            os.unlink(path)
        response = self.client.synthesize_speech(
            input=texttospeech.SynthesisInput(text=text),
            voice=self.voice,
            audio_config=texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.LINEAR16,
                effects_profile_id=["small-bluetooth-speaker-class-device"],
                sample_rate_hertz=16000,
                speaking_rate=self.speed * float(options.get("speed", 1.0))
            )
        )
        with open(path, "wb") as out:
            out.write(response.audio_content)


def build(engine, voice, speed, silence, csv, cache=None, only_missing=False, recreate_cache=False):
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
        print("[%s]" % path)
        if cache and not recreate_cache:
            tts_output = cache.get(text, options)
            if tts_output:
                print("  in cache")
                encode(tts_output, path, silence=silence)
                continue
        temp_path = tempfile.mkdtemp()
        tts_output = os.path.join(temp_path, "output.wav")
        generator.build(tts_output, text, options)
        cache.push(tts_output, text, options)
        encode(tts_output, path, silence=silence)
        shutil.rmtree(temp_path)

    return 0


def main():
    if sys.version_info < (3, 0, 0):
        print("%s requires Python 3. Terminating." % __file__)
        return 1
    
    parser = argparse.ArgumentParser(description="Build Ethos audio packs")
    parser.add_argument("-p", "--packs", action="append", help="packs", required=True)
    parser.add_argument('--recreate-cache', action="store_true", help="Recreate files cache")
    args = parser.parse_args()

    packs = json.loads(open('audio_packs.json').read())
    for key in (packs.keys() if "ALL" in args.packs else args.packs):
        if key not in packs.keys():
            print("Unknown pack %s, supported packs: %r" % (key, list(packs.keys())))
            exit(-1)

        language = key.split('/')[0]
        os.makedirs(os.path.join(AUDIO_DIR, key, "system"), exist_ok=True)
        os.chdir(os.path.join(AUDIO_DIR, key))
        pack = packs[key]
        csv = os.path.join(AUDIO_DIR, language, "%s.csv" % language)
        build(pack["engine"], pack["voice"], pack.get("speed", 1.0), pack.get("silence", False), csv, "/var/cache/ethos", only_missing=False, recreate_cache=args.recreate_cache)


if __name__ == "__main__":
    exit(main())

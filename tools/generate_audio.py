"""Original deterministic synthesis for Rừng Tàn Lửa; no samples/services.

python3 tools/generate_audio.py [--output /path/to/assets]
Requires numpy and ffmpeg (libvorbis). Produces 4 modal 28s stereo scores,
4 periodic stereo ambience beds and 13 mono effects at 44.1 kHz. Music is
composed on a circular buffer: note/reverb tails wrap rather than being cut.
PCM RMS normalization leaves >=3 dB headroom; decoded OGG peak and seams are
validated before files are published. Importing this module has no IO effects.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SR = 44100
DURATION = 28
REGIONS = ("camp", "forest", "creek", "ruins")
AMBIENTS = ("wind", "water", "birds", "fire")
SFX_KEYS = ("step", "attack", "hit", "dodge", "stone", "pickup", "heal", "quest", "death", "click", "bow", "magic", "bear")


def normalize(signal: np.ndarray, rms: float = 0.12) -> np.ndarray:
    """Static gain only: no limiter pumping and no time-varying loop boundary."""
    signal = np.asarray(signal, dtype=np.float64)
    if not np.isfinite(signal).all():
        raise ValueError("non-finite audio samples")
    peak = float(np.max(np.abs(signal))) if signal.size else 0.0
    if peak < 1e-12:
        return np.zeros_like(signal)
    measured = float(np.sqrt(np.mean(signal * signal)))
    return signal * min(rms / max(measured, 1e-12), 0.70 / peak)


def periodic_noise(n: int, rng: np.random.Generator, low: float, high: float) -> np.ndarray:
    """Band-shaped real FFT noise; circular by construction, no noise seam."""
    bins = np.fft.rfftfreq(n, 1 / SR)
    spectrum = np.fft.rfft(rng.standard_normal(n))
    shape = np.exp(-((bins / high) ** 2)) * (1 - np.exp(-((bins / low) ** 2)))
    noise = np.fft.irfft(spectrum * shape, n=n)
    return noise / max(float(np.std(noise)), 1e-9)


def wrap_note(target: np.ndarray, note: np.ndarray, start: float, pan: float, gain: float = 1.0) -> None:
    indices = (np.arange(len(note)) + round(start * SR)) % len(target)
    target[indices, 0] += note * gain * np.sqrt((1 - pan) / 2)
    target[indices, 1] += note * gain * np.sqrt((1 + pan) / 2)


def tone(freq: float, duration: float, voice: str = "bell") -> np.ndarray:
    t = np.arange(round(duration * SR)) / SR
    if voice == "pad":
        env = np.sin(np.pi * np.arange(len(t)) / max(1, len(t) - 1)) ** 2
        return env * (np.sin(2 * np.pi * freq * t) + 0.17 * np.sin(2 * np.pi * freq * 2 * t))
    env = (1 - np.exp(-t * 90)) * np.exp(-t * (2.1 if voice == "wood" else 1.1))
    env *= np.minimum(1, (duration - t) / 0.08)
    ratios = (1, 2, 3) if voice == "wood" else (1, 2.002, 3.997)
    return env * sum(gain * np.sin(2 * np.pi * freq * ratio * t)
                     for gain, ratio in zip((1.0, 0.22, 0.07), ratios))


def music(region: str) -> np.ndarray:
    """Four related original D-modal miniatures, eight 3.5s bars / 28 seconds."""
    if region not in REGIONS:
        raise ValueError(region)
    n = SR * DURATION
    result = np.zeros((n, 2), dtype=np.float64)
    # D Dorian warmth in camp/creek, D Aeolian in forest, suspended ruins.
    third = 3
    sixth = 9 if region in ("camp", "creek") else 8
    chords = [(0, 7, 12), (third, 10, 14), (5, 12, 17), (0, 7, 14)]
    melody = {
        "camp": (12, 14, 15, 19, 17, 14, 12, sixth, 7, 12, 14, 19, 17, 15, 14, 7),
        "forest": (12, 7, 10, 14, 15, 14, 7, 5, 12, 10, 7, 3, 5, 7, 14, 10),
        "creek": (19, 14, 17, 21, 19, 17, 14, 12, 14, 17, 19, 21, 24, 19, 17, 14),
        "ruins": (12, 19, 14, 7, 10, 17, 14, 5, 12, 19, 22, 17, 14, 10, 7, 2),
    }[region]
    for bar in range(8):
        for index, semitone in enumerate(chords[(bar // 2) % 4]):
            frequency = 146.8324 * 2 ** (semitone / 12)
            wrap_note(result, tone(frequency, 7, "pad"), bar * 3.5 - 1.75,
                      (-0.45, 0.0, 0.45)[index], 0.12)
        root_note = chords[(bar // 2) % 4][0]
        wrap_note(result, tone(73.4162 * 2 ** (root_note / 12), 4.5, "pad"),
                  bar * 3.5, 0, 0.10)
    for index, semitone in enumerate(melody):
        frequency = 146.8324 * 2 ** (semitone / 12)
        note = tone(frequency, 3.2, "wood" if region == "camp" else "bell")
        pan = (-0.4, 0.3, -0.15, 0.5)[index % 4]
        start = index * 1.75 + (0.4375 if index % 3 == 1 else 0)
        wrap_note(result, note, start, pan, 0.13 if region != "ruins" else 0.09)
        for delay, gain in ((0.4375, 0.032), (0.875, 0.015)):
            wrap_note(result, note, start + delay, -pan, gain)
    # Circular small-room echoes retain tails across the exact loop boundary.
    result += np.roll(result, round(SR * 0.193), axis=0)[:, ::-1] * 0.09
    return normalize(result, 0.115)


def ambient(key: str) -> np.ndarray:
    if key not in AMBIENTS:
        raise ValueError(key)
    rng = np.random.default_rng(620 + AMBIENTS.index(key))
    n = SR * DURATION
    t = np.arange(n) / SR
    result = np.zeros((n, 2), dtype=np.float64)
    for channel in range(2):
        if key == "wind":
            bed = periodic_noise(n, rng, 40, 650)
            result[:, channel] = bed * (0.32 + 0.15 * np.sin(2 * np.pi * t / 14 + channel * 0.7))
        elif key == "water":
            bed = periodic_noise(n, rng, 180, 3200)
            result[:, channel] = bed * (0.23 + 0.06 * np.sin(2 * np.pi * t / 7 + channel))
        elif key == "fire":
            result[:, channel] = periodic_noise(n, rng, 65, 470) * 0.06
        else:
            result[:, channel] = periodic_noise(n, rng, 200, 1700) * 0.006
    if key == "birds":
        for index, start in enumerate((1.6, 4.8, 9.2, 15.4, 21.0, 25.3)):
            for chirp in range(2 + index % 2):
                tt = np.arange(round(SR * 0.19)) / SR
                frequency = (1600 + 170 * (index % 3)) + 1300 * np.sin(np.pi * tt / 0.19)
                note = np.sin(2 * np.pi * np.cumsum(frequency) / SR) * np.sin(np.pi * tt / 0.19) ** 2
                wrap_note(result, note, start + chirp * 0.27, (-0.65, 0.55)[index % 2], 0.075)
    elif key in ("water", "fire"):
        for _ in range(65 if key == "water" else 90):
            duration = rng.uniform(0.015, 0.07)
            tt = np.arange(round(duration * SR)) / SR
            if key == "water":
                frequency = rng.uniform(600, 1500)
                note = np.sin(2 * np.pi * (frequency * tt - 1800 * tt * tt))
            else:
                note = rng.standard_normal(len(tt))
            note *= np.sin(np.pi * tt / duration) ** 2 * np.exp(-tt * 50)
            wrap_note(result, note, rng.uniform(0, DURATION), rng.uniform(-0.7, 0.7), 0.10)
    # Suppress only the tiny edge discontinuity of band-limited random textures;
    # a 15 ms blend towards a shared endpoint preserves continuous ambience.
    edge = round(SR * 0.015)
    shared = (result[0] + result[-1]) * 0.5
    weight = (0.5 - 0.5 * np.cos(np.linspace(0, np.pi, edge)))[:, None]
    result[:edge] = shared + (result[:edge] - shared) * weight
    result[-edge:] = shared + (result[-edge:] - shared) * weight[::-1]
    return normalize(result, 0.085 if key != "birds" else 0.032)


def sfx(key: str) -> np.ndarray:
    if key not in SFX_KEYS:
        raise ValueError(key)
    durations = dict(zip(SFX_KEYS, (0.15, 0.28, 0.23, 0.38, 0.28, 0.58, 1.2, 2.2, 1.8, 0.065, 0.32, 0.7, 0.85)))
    duration = durations[key]
    t = np.arange(round(duration * SR)) / SR
    rng = np.random.default_rng(700 + SFX_KEYS.index(key))
    noise = rng.standard_normal(len(t))
    soft = np.convolve(noise, np.ones(13) / 13, mode="same")
    if key in ("step", "hit", "stone"):
        frequency = {"step": 100, "hit": 145, "stone": 640}[key]
        result = (soft * 0.55 + np.sin(2 * np.pi * frequency * t) * 0.3) * np.exp(-t * 25)
        if key == "stone":
            result += np.sin(2 * np.pi * 970 * t) * np.exp(-t * 40) * 0.18
    elif key in ("attack", "dodge", "bow"):
        result = soft * np.sin(np.pi * t / duration) ** 1.7
        if key == "bow":
            result += np.sin(2 * np.pi * (260 * t - 170 * t * t)) * np.exp(-t * 17) * 0.22
    elif key in ("pickup", "heal", "quest", "magic"):
        result = np.zeros(len(t))
        notes = {"pickup": (587.33, 880), "heal": (293.66, 369.99, 440),
                 "quest": (293.66, 440, 587.33, 659.25, 880), "magic": (440, 622.25, 880)}[key]
        for index, frequency in enumerate(notes):
            start = round(index * duration / (len(notes) + 2) * SR)
            note = tone(frequency, (len(t) - start) / SR)
            result[start:] += note * 0.3
    elif key == "death":
        result = (np.sin(2 * np.pi * (150 * t - 25 * t * t)) + soft * 0.4) * np.exp(-t * 2.7)
    elif key == "bear":
        result = (np.sin(2 * np.pi * 76 * t + 0.7 * np.sin(2 * np.pi * 23 * t)) + soft) * np.sin(np.pi * t / duration) ** 2
    else:
        result = np.sin(2 * np.pi * 960 * t) * np.exp(-t * 70)
    edge = min(round(0.009 * SR), len(t) // 3)
    result[:edge] *= np.linspace(0, 1, edge) ** 2
    result[-edge:] *= np.linspace(1, 0, edge) ** 2
    return normalize(result, 0.16 if key not in ("step", "click") else 0.10)


def encode(signal: np.ndarray, path: Path, ffmpeg: str, loop: bool) -> dict:
    """Encode then measure real decoded Vorbis, not merely the source PCM."""
    path.parent.mkdir(parents=True, exist_ok=True)
    channels = 1 if signal.ndim == 1 else signal.shape[1]
    with tempfile.TemporaryDirectory(prefix="rung-audio-") as temporary:
        source = Path(temporary) / "source.wav"
        encoded = Path(temporary) / "encoded.ogg"
        with wave.open(str(source), "wb") as output:
            output.setnchannels(channels)
            output.setsampwidth(2)
            output.setframerate(SR)
            output.writeframes((np.clip(signal, -1, 1) * 32767).astype("<i2").tobytes())
        subprocess.run([ffmpeg, "-v", "error", "-nostdin", "-y", "-i", str(source),
                        "-map_metadata", "-1", "-c:a", "libvorbis", "-q:a", "5",
                        "-metadata", "artist=Rung Tan Lua original procedural score",
                        "-metadata", f"title={path.stem}", str(encoded)], check=True)
        raw = subprocess.run([ffmpeg, "-v", "error", "-nostdin", "-i", str(encoded),
                              "-f", "f32le", "-ar", str(SR), "-ac", str(channels), "pipe:1"],
                             check=True, stdout=subprocess.PIPE).stdout
        decoded = np.frombuffer(raw, dtype="<f4").reshape(-1, channels)
        peak = float(np.max(np.abs(decoded)))
        seam = float(np.max(np.abs(decoded[-1] - decoded[0])))
        oversampled_raw = subprocess.run([
            ffmpeg, "-v", "error", "-nostdin", "-i", str(encoded),
            "-af", "aresample=176400", "-f", "f32le", "-ac", str(channels), "pipe:1"],
            check=True, stdout=subprocess.PIPE).stdout
        true_peak = float(np.max(np.abs(np.frombuffer(oversampled_raw, dtype="<f4"))))
        if not np.isfinite(decoded).all() or peak > 10 ** (-1.5 / 20):
            raise ValueError(f"Decoded clipping/headroom failure: {path} {peak=}")
        if not np.isfinite(true_peak) or true_peak > 10 ** (-1.5 / 20):
            raise ValueError(f"4x oversampled intersample headroom failure: {path} {true_peak=}")
        if loop and seam > 0.04:
            raise ValueError(f"Decoded loop discontinuity: {path} {seam=}")
        shutil.copyfile(encoded, path)
    return {"path": f"{path.parent.name}/{path.name}", "seconds": len(decoded) / SR,
            "channels": channels, "sample_rate": SR, "loop": loop,
            "peak_dbfs": round(20 * np.log10(max(peak, 1e-12)), 3),
            "true_peak_dbfs": round(20 * np.log10(max(true_peak, 1e-12)), 3),
            "rms_dbfs": round(20 * np.log10(max(float(np.sqrt(np.mean(decoded ** 2))), 1e-12)), 3),
            "boundary_delta": round(seam, 6), "bytes": path.stat().st_size}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "assets")
    args = parser.parse_args()
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg with libvorbis is required")
    report = []
    for key in REGIONS:
        report.append(encode(music(key), args.output / "music" / f"{key}.ogg", ffmpeg, True))
    for key in AMBIENTS:
        report.append(encode(ambient(key), args.output / "ambient" / f"{key}.ogg", ffmpeg, True))
    for key in SFX_KEYS:
        report.append(encode(sfx(key), args.output / "sfx" / f"{key}.ogg", ffmpeg, False))
    (args.output / "audio_manifest.json").write_text(json.dumps({
        "provenance": "Original mathematical synthesis; no external audio, samples, services or costs.",
        "seed_policy": "Fixed local numpy PCG64 seeds; original modal note sequences.",
        "normalization": "Static RMS gain, PCM peak <= -3.098 dBFS, decoded sample and 4x oversampled true peak <= -1.5 dBFS.",
        "tracks": report}, indent=2) + "\n", encoding="utf-8")
    print(f"Generated and decoded/validated {len(report)} original OGG files in {args.output}")


if __name__ == "__main__":
    main()

"""Real synthesis tests: silence, nondeterminism, clipping and loop clicks regress here."""
import importlib.util
import json
from pathlib import Path
import unittest

import numpy as np

GENERATOR = Path(__file__).resolve().parents[1] / "tools/generate_audio.py"


class AudioAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generator = None
        if GENERATOR.exists():
            spec = importlib.util.spec_from_file_location("generate_audio", GENERATOR)
            cls.generator = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(cls.generator)

    def module(self):
        self.assertIsNotNone(self.generator, "original audio generator must exist")
        return self.generator

    def test_music_is_audible_seamless_stereo_and_deterministic(self):
        g = self.module()
        for region in ("camp", "forest", "creek", "ruins"):
            signal = g.music(region)
            self.assertEqual(signal.shape, (44100 * 28, 2))
            self.assertTrue(np.isfinite(signal).all())
            self.assertGreater(float(np.sqrt(np.mean(signal ** 2))), 0.03)
            self.assertLessEqual(float(np.max(np.abs(signal))), 0.71)
            self.assertLess(float(np.max(np.abs(signal[0] - signal[-1]))), 0.015)
            self.assertFalse(np.array_equal(signal[:, 0], signal[:, 1]))
        self.assertTrue(np.array_equal(g.music("camp"), g.music("camp")))

    def test_ambient_textures_are_nonclipping_periodic(self):
        g = self.module()
        for key in ("wind", "water", "birds", "fire"):
            signal = g.ambient(key)
            self.assertEqual(signal.shape, (44100 * 28, 2))
            self.assertGreater(float(np.max(np.abs(signal))), 0.02)
            self.assertLessEqual(float(np.max(np.abs(signal))), 0.71)
            self.assertLess(float(np.max(np.abs(signal[0] - signal[-1]))), 0.03)

    def test_sfx_are_distinct_mono_and_fade_to_silence(self):
        g = self.module()
        keys = ("step", "attack", "hit", "dodge", "stone", "pickup", "heal", "quest", "death", "click", "bow", "magic", "bear")
        signatures = set()
        for key in keys:
            signal = g.sfx(key)
            self.assertEqual(signal.ndim, 1)
            self.assertGreater(len(signal), 1000)
            self.assertLess(len(signal), 44100 * 4)
            self.assertTrue(np.isfinite(signal).all())
            self.assertLessEqual(float(np.max(np.abs(signal))), 0.71)
            self.assertLess(abs(float(signal[0])), 0.001)
            self.assertLess(abs(float(signal[-1])), 0.001)
            signatures.add(signal.tobytes())
        self.assertEqual(len(signatures), 13)

    def test_silence_and_invalid_samples_normalize_safely(self):
        g = self.module()
        self.assertTrue(np.array_equal(g.normalize(np.zeros(20)), np.zeros(20)))
        with self.assertRaises(ValueError):
            g.normalize(np.array([np.nan, 1.0]))

    def test_encoded_delivery_matches_audio_contract(self):
        manifest = GENERATOR.parents[1] / "assets/audio_manifest.json"
        if not manifest.exists():
            self.skipTest("run tools/generate_audio.py for encoded delivery validation")
        data = json.loads(manifest.read_text())
        self.assertEqual(len(data["tracks"]), 21)
        for track in data["tracks"]:
            self.assertLessEqual(track["peak_dbfs"], -1.5)
            self.assertIn("true_peak_dbfs", track, "encoded files must measure intersample headroom")
            self.assertLessEqual(track["true_peak_dbfs"], -1.5)
            self.assertEqual(track["sample_rate"], 44100)
            self.assertTrue((manifest.parent / track["path"]).exists())
            if track["loop"]:
                self.assertAlmostEqual(track["seconds"], 28, places=2)
                self.assertLess(track["boundary_delta"], 0.04)
            else:
                self.assertEqual(track["channels"], 1)
                self.assertLess(track["bytes"], 200_000)


if __name__ == "__main__":
    unittest.main()

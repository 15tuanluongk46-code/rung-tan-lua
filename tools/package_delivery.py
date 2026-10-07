"""Collect real captures and ship runnable Linux plus source; never overwrite user data."""
from pathlib import Path
import hashlib
import shutil
import tarfile

ROOT = Path(__file__).resolve().parents[1]
CAPTURES = Path.home() / ".local/share/godot/app_userdata/Rừng Tàn Lửa/captures"

def main():
    destination = ROOT / "docs/screenshots"
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("camp", "forest", "creek", "ruins", "menu", "pause", "settings", "gameplay-input"):
        source = CAPTURES / f"{name}.png"
        if source.is_file():
            shutil.copy2(source, destination / source.name)
        elif not (destination / source.name).is_file():
            raise RuntimeError(f"Missing real capture in both {source} and {destination}")
    binary = ROOT / "build/linux/RungTanLua.x86_64"
    if not binary.is_file():
        raise RuntimeError("Export Linux first")
    for source, name in ((ROOT / "LICENSE", "LICENSE"), (ROOT / "assets/CREDITS.md", "CREDITS.md"),
                         (ROOT / "assets/fonts/LICENSE-DejaVu.txt", "LICENSE-DejaVu.txt")):
        shutil.copy2(source, binary.parent / name)
    (binary.parent / "README.txt").write_text(
        "Rừng Tàn Lửa — Linux x86_64\nRun ./RungTanLua.x86_64 (chmod +x if needed).\n"
        "WASD move; mouse aim; LMB spear; RMB stone; Space dodge; E interact; Q heal; Esc pause.\n"
        "Runs are not saved on exit. Settings persist.\n"
        "Godot Engine: https://godotengine.org/license/ (including third-party notices).\n", encoding="utf-8")
    out = ROOT / "build"
    with tarfile.open(out / "RungTanLua-Linux-x86_64.tar.gz", "w:gz") as archive:
        archive.add(binary.parent, arcname="RungTanLua-Linux")
    with tarfile.open(out / "RungTanLua-Source.tar.gz", "w:gz") as archive:
        for path in sorted(ROOT.rglob("*")):
            relative = path.relative_to(ROOT)
            if any(part in {"build", ".godot", "__pycache__", ".git", ".venv"} for part in relative.parts):
                continue
            if path.name == '.env' or path.name.startswith('.env.') or path.suffix == '.log':
                continue
            if path.is_file():
                archive.add(path, arcname=str(Path("rung-tan-lua") / relative))
    entries = []
    for path in (binary, out / "RungTanLua-Linux-x86_64.tar.gz", out / "RungTanLua-Source.tar.gz"):
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        entries.append(f"{digest}  {path.relative_to(out)}")
        print(path, path.stat().st_size, digest)
    (out / "SHA256SUMS").write_text("\n".join(entries)+"\n")

if __name__ == "__main__":
    main()

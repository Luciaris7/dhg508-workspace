"""Run every gate on Windows/Linux with isolated saves. Requires Python 3 + Godot."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GATES = [
    ('check', 'check', [], r'CHECK: \d+ files, 0 failed'),
    ('ephem', 'ephem_test', [], r'EPHEM PASS'),
    ('motion', 'motion_test', [], r'MOTION PASS'),
    ('menu', 'menu_test', [], r'MENU PASS'),
    ('endings', 'ending_test', [], r'ENDINGS PASS'),
    ('day5', 'day5_test', [], r'DAY5 PASS'),
    ('dream', 'dream_test', [], r'DREAM PASS'),
    ('ufo', 'ufo_test', [], r'UFO PASS'),
    # one full playthrough per ending (docs/MYSTERY_BIBLE.md §6)
    ('play-en', 'playthrough', ['answers=ynnnyyy', 'lang=en', 'route=bad'], r'PLAYTHROUGH PASS'),
    ('play-zh', 'playthrough', ['answers=yyyynyy', 'lang=zh', 'route=normal'], r'PLAYTHROUGH PASS'),
    ('play-good', 'playthrough', ['answers=ynnyyyy', 'lang=en', 'route=good'], r'PLAYTHROUGH PASS'),
]


def main():
    if sys.platform == 'darwin':
        raise SystemExit('This runner isolates saves on Windows/Linux only.')
    godot = os.environ.get('GODOT_EXE') or shutil.which('godot') or shutil.which('godot4')
    if not godot:
        raise SystemExit('Set GODOT_EXE to the Godot 4.6+ executable.')
    logs = ROOT / 'tests' / '_logs'
    logs.mkdir(exist_ok=True)
    (logs / '.gdignore').touch()
    with tempfile.TemporaryDirectory(prefix='audience-tests-') as temporary:
        for name, scene, arguments, marker in [('import', None, [], None)] + GATES:
            profile = Path(temporary) / name
            profile.mkdir()
            env = os.environ.copy()
            env.update(XDG_DATA_HOME=str(profile), APPDATA=str(profile), LOCALAPPDATA=str(profile))
            command = [godot, '--headless', '--path', str(ROOT)]
            if scene is None:
                command += ['--import']
            else:
                command += ['--fixed-fps', '60', '--quit-after', '36000', f'res://tests/{scene}.tscn']
                if arguments:
                    command += ['--'] + arguments
            print(f'=== {name}', flush=True)
            try:
                result = subprocess.run(command, env=env, stdout=subprocess.PIPE,
                                        stderr=subprocess.STDOUT, timeout=900,
                                        encoding='utf-8', errors='replace')
            except subprocess.TimeoutExpired as error:
                (logs / f'{name}.log').write_bytes(error.stdout or b'')
                raise SystemExit(f'{name}: timeout; see {logs / (name + ".log")}')
            (logs / f'{name}.log').write_text(result.stdout, encoding='utf-8')
            for line in result.stdout.splitlines():
                if re.search(r'CHECK:|EPHEM PASS|MOTION |MENU |ENDINGS |DAY5 |DREAM |UFO |PLAYTHROUGH |^FAIL|SCRIPT ERROR', line):
                    print(line)
            # Fixed-FPS headless runs can report retained audio resources at
            # process shutdown. Preserve the log, but reject every other error.
            diagnostic = re.sub(r'^ERROR: \d+ resources still in use at exit.*$', '', result.stdout, flags=re.M)
            if result.returncode or (marker and not re.search(marker, result.stdout)) or re.search(r'^ERROR:|SCRIPT ERROR:|^FAIL\s', diagnostic, re.M):
                raise SystemExit(f'{name} failed; see {logs / (name + ".log")}')
    print('TEST RUN PASS')


if __name__ == '__main__':
    main()

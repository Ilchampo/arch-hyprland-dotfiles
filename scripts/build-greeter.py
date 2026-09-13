#!/usr/bin/env python3
"""Build root-installable ReGreet assets from the existing desktop palettes."""
import argparse
import importlib.machinery
import importlib.util
from pathlib import Path
import shutil
import tomllib

REPO = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('theme_switch', str(REPO / '.local/bin/theme-switch'))
spec = importlib.util.spec_from_loader(loader.name, loader)
themes = importlib.util.module_from_spec(spec)
loader.exec_module(themes)


def build(destination):
    source = REPO / '.config/themes'
    for palette in sorted(source.glob('*/palette.json')):
        slug = palette.parent.name
        data = themes.load_theme(palette.parent)
        output = destination / 'themes' / slug
        output.mkdir(parents=True, exist_ok=True)
        for template in (REPO / 'system/greetd/templates').iterdir():
            text = themes.render(template.read_text(), data, slug)
            if template.suffix == '.toml':
                tomllib.loads(text.decode())
            (output / template.name).write_bytes(text)
        shutil.copyfile(palette.parent / 'wallpaper.png', output / 'wallpaper.png')
    if not (destination / 'themes/verdant/regreet.toml').exists():
        raise ValueError('The fallback Verdant theme must be present')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    build(parser.parse_args().destination)

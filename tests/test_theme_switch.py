"""Integration checks in temporary home directories; never touch the live desktop."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / '.local/bin/theme-switch'
loader = importlib.machinery.SourceFileLoader('theme_switch', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class Themes(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        shutil.copytree(REPO / '.config', self.root / '.config')

    def tearDown(self):
        self.temp.cleanup()

    def run_switch(self, *args):
        return subprocess.run([str(SCRIPT), '--root', str(self.root), '--no-reload', *args],
                              capture_output=True, text=True)

    def test_roundtrip_and_restore(self):
        self.assertEqual(self.run_switch('verdant').returncode, 0)
        appearance = self.root / '.config/hypr/config/appearance.lua'
        initial = appearance.read_bytes()
        self.assertEqual(self.run_switch('abyss').returncode, 0)
        self.assertIn('061521', appearance.read_text())
        self.assertIn('gtk-theme-name=Abyss', (self.root / '.config/gtk-3.0/settings.ini').read_text())
        self.assertIn('/abyss/wallpaper.png', (self.root / '.config/hypr/hyprpaper.conf').read_text())
        self.assertIn('#398DA8', (self.root / '.local/share/icons/Abyss/scalable/places/folder.svg').read_text())
        # Simulate apply_changes.sh copying the repository defaults over outputs.
        shutil.copyfile(REPO / '.config/hypr/config/appearance.lua', appearance)
        self.assertEqual(self.run_switch('--restore').returncode, 0)
        self.assertIn('061521', appearance.read_text())
        self.assertEqual(self.run_switch('verdant').returncode, 0)
        self.assertEqual(appearance.read_bytes(), initial)
        self.assertEqual((self.root / '.local/state/theme-switch/current').read_text(), 'verdant\n')

    def test_invalid_input_does_not_modify_files(self):
        original = (self.root / '.config/waybar/style.css').read_bytes()
        self.assertNotEqual(self.run_switch('../bad').returncode, 0)
        palette = self.root / '.config/themes/abyss/palette.json'
        data = json.loads(palette.read_text()); data['colors']['bg'] = 'not-a-color'
        palette.write_text(json.dumps(data))
        self.assertNotEqual(self.run_switch('abyss').returncode, 0)
        self.assertEqual((self.root / '.config/waybar/style.css').read_bytes(), original)
        self.assertFalse((self.root / '.local/state/theme-switch/current').exists())

    def test_cancel_and_selection(self):
        themes = {'verdant': {'name': 'Verdant'}, 'abyss': {'name': 'Abyss'}}
        with patch.object(module.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', '')):
            self.assertIsNone(module.choose(self.root, themes, 'verdant'))
        with patch.object(module.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'Abyss\n', '')):
            self.assertEqual(module.choose(self.root, themes, 'verdant'), 'abyss')

    def test_runtime_commands_target_every_monitor(self):
        calls = []
        def fake(args):
            calls.append(args)
            return subprocess.CompletedProcess(args, 0, '[{"name":"HDMI-A-1"},{"name":"DP-1"}]' if args == ['hyprctl','-j','monitors'] else '', '')
        with patch.object(module, 'command', side_effect=fake), patch.dict(module.os.environ, {'HYPRLAND_INSTANCE_SIGNATURE': 'test'}):
            self.assertEqual(module.refresh(self.root, 'abyss', {'name': 'Abyss'}), [])
        wallpapers = [c[-1] for c in calls if c[:3] == ['hyprctl','hyprpaper','wallpaper']]
        self.assertEqual(len(wallpapers), 3)
        self.assertTrue(any(c.startswith('DP-1,') for c in wallpapers))
        self.assertIn(['gsettings','set','org.gnome.desktop.interface','gtk-theme','Abyss'], calls)
        self.assertIn(['makoctl','reload'], calls)
        self.assertFalse(any('thunar' in c for c in calls))

    def test_login_theme_sync_is_optional_and_limited_to_ids(self):
        selection = self.root / 'login-current'
        assets = self.root / 'login-themes'
        self.assertIsNone(module.sync_greeter('abyss', selection, assets))
        selection.write_text('verdant\n')
        self.assertIn('not installed', module.sync_greeter('abyss', selection, assets))
        (assets / 'abyss').mkdir(parents=True)
        (assets / 'abyss/regreet.toml').write_text('skip_selection = true\n')
        self.assertIsNone(module.sync_greeter('abyss', selection, assets))
        self.assertEqual(selection.read_text(), 'abyss\n')
        self.assertIn('Invalid', module.sync_greeter('../abyss', selection, assets))
        self.assertEqual(selection.read_text(), 'abyss\n')

    def test_login_sync_rejects_symlink(self):
        target = self.root / 'protected'
        target.write_text('unchanged')
        selection = self.root / 'login-current'
        selection.symlink_to(target)
        assets = self.root / 'login-themes'
        (assets / 'abyss').mkdir(parents=True)
        (assets / 'abyss/regreet.toml').write_text('')
        self.assertIn('Could not update', module.sync_greeter('abyss', selection, assets))
        self.assertEqual(target.read_text(), 'unchanged')

    def test_file_transaction_rolls_back(self):
        a, b = self.root / 'a', self.root / 'b'
        a.write_bytes(b'old'); b.write_bytes(b'old')
        original = module.atomic_write
        def fail_second(path, content):
            if path == b:
                raise OSError('simulated full disk')
            original(path, content)
        with patch.object(module, 'atomic_write', side_effect=fail_second):
            with self.assertRaises(OSError):
                module.install({a:b'new', b:b'new'})
        self.assertEqual(a.read_bytes(), b'old')


if __name__ == '__main__':
    unittest.main()

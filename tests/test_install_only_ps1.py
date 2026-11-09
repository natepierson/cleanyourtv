"""install-only.ps1 pushes an APK and stops.

The TCL 75QM751G first install must not hand Home over, turn a package off, enable a key
helper, or restart the TV. launcher/build-and-install.ps1 still does the handover; this
file is the separate script, and these checks keep the two from growing into each other.

Run from the repository root: python3 -m unittest discover -s tests -v
"""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PS1 = ROOT / "launcher" / "install-only.ps1"


class InstallOnlyScriptTest(unittest.TestCase):
    def setUp(self):
        self.text = PS1.read_text(encoding="utf-8")

    def test_script_exists_and_installs_in_place(self):
        self.assertIn("pm install -r", self.text)
        self.assertIn("b64push.py", self.text)
        self.assertNotIn("install -r -d", self.text)
        self.assertNotIn("bypass-low-target-sdk-block", self.text)

    def test_it_does_not_take_over_the_tv(self):
        for banned in (
            "set-home-activity",
            "pm disable",
            "pm uninstall",
            "pm hide",
            "pm block",
            "reboot",
            "InputKeyService",
            "HomeKeyService",
            "enabled_accessibility_services",
            "WRITE_SECURE_SETTINGS",
            "setupwraith",
            "FORCE_SETUPWRAITH",
            "FORCE_HOME",
        ):
            self.assertNotIn(banned, self.text, banned)

    def test_a_verification_refusal_stops(self):
        self.assertIn("INSTALL_FAILED_VERIFICATION_FAILURE", self.text)
        self.assertIn("INSTALL_FAILED_UPDATE_INCOMPATIBLE", self.text)
        self.assertIn("Stopping.", self.text)

    def test_parameters_match_the_windows_page(self):
        # tests/test_ps1_invocations.py reads this param block.
        self.assertIn("[string]$TvHost", self.text)
        self.assertIn("[string]$Apk", self.text)

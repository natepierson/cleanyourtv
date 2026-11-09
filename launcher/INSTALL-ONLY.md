# TCL 75QM751G: build and install only

This launcher checkout is configured for a TCL 75QM751G (QM7, 2024), board `G08`, Android 14, SDK 34, build family AU14. Read [docs/devices/tcl-75qm751g-qm7.md](../docs/devices/tcl-75qm751g-qm7.md) before any later handover. That note is from other units on the same board and build. This page does not add a debloat list and does not turn anything off.

The APK built from this tree was not installed on a television and was not opened in an emulator. Checks were the unit tests, Android lint, and the release APK itself.

## What the APK is

| | |
|---|---|
| Application id | `com.gathin.tvhome` |
| Home activity | `com.gathin.tvhome.MainActivity` (`com.gathin.tvhome/.MainActivity`) |
| Also listed as | `LEANBACK_LAUNCHER`, so it shows in the stock apps row |
| minSdk / targetSdk | 26 / 34 |
| Version | 3.4 (versionCode 13) |
| Typeface | Outfit, SIL Open Font License, [FONT-LICENSE-OFL.txt](FONT-LICENSE-OFL.txt) |
| Window | `Theme.TvHome` sets `windowIsTranslucent`, `windowIsFloating` and `windowSwipeToDismiss` to false |

There is no `INTERNET` permission, no blur, no video, and no polling. The Wi-Fi pill reads the connection Android already has. `boot_to_live_tv` and `power_on_home` stay off.

`launcher/build-and-install.ps1` and `launcher/build-and-install.sh` are unchanged. They hand Home over and can turn the stock launcher off. Do not run them for this install.

## Dock

Five columns, left to right. `fill_dock` is false, so a missing app leaves an empty slot.

| Order | App | Package |
|---|---|---|
| 1 | YouTube TV | `com.google.android.youtube.tvunplugged` |
| 2 | Netflix | `com.netflix.ninja` |
| 3 | Prime Video | `com.amazon.amazonvideo.livingroom` |
| 4 | YouTube | `com.google.android.youtube.tv` |
| 5 | Tubi | `com.tubitv` |

One row of the same grid shows under the dock. Down moves one row in that column and scrolls the rest up. Up from the dock moves to the top bar. Left and Right at the ends of the top bar stay on the bar. The last focused tile is kept.

The dock band is a lighter rounded glass strip: a painted gradient, the same idea as the pills, not a blur. The focused dock app's name sits above it in large light type, with a glow sampled from its banner. The glow changes colour in one frame. The focused tile scales slightly and shows its name underneath. One glass highlight springs between tiles.

The top left is the greeting, a thin clock, and the date, in Outfit. The top right pills are Inputs, the network name, and Settings. Inputs opens the existing compact menu of HDMI, AV, and Live TV (`com.tcl.tv`) through the TV input framework.

## Build on Windows

JDK 17 or newer, Android SDK platform 34, and build-tools 34.0.0. This tree was built with JDK 21 and AGP 8.5.2; the project text still names JDK 17.

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
cd launcher
if (-not (Test-Path local.properties)) {
    "sdk.dir=$($env:ANDROID_HOME -replace '\\', '\\')" | Out-File -Encoding ascii local.properties
}
.\gradlew.bat --no-daemon assembleRelease
```

The APK is `launcher\app\build\outputs\apk\release\app-release.apk`. It must stay under 589824 bytes. Release is signed with the debug key so a later install of the same tree replaces it. A different signature is a refusal: stop, and do not remove the copy already on the TV.

## Install

From the repository root, once, with the TV's address. This only uploads the APK and runs `pm install -r`.

```powershell
python -m venv tools\venv
tools\venv\Scripts\python.exe -m pip install -r tools\requirements.txt
powershell -ExecutionPolicy Bypass -File launcher\install-only.ps1 -TvHost 192.168.1.50
```

An APK that is not the one Gradle just wrote:

```powershell
powershell -ExecutionPolicy Bypass -File launcher\install-only.ps1 -TvHost 192.168.1.50 -Apk C:\tvhome.apk
```

When the TV prints `Success`, the script grants `ACCESS_FINE_LOCATION`. It does not turn Location on. With Location off, Android 14 shows "Wi-Fi" on the pill instead of the network name. Ethernet shows "Ethernet".

If the TV refuses the install (`INSTALL_FAILED_VERIFICATION_FAILURE`, a signature mismatch, an older SDK, or any other `INSTALL_FAILED`), the script stops. It does not try again, and it does not change Home.

The Home button still opens the stock launcher. setupwraith stays as it was. Open **Home** from the stock apps row when you want to look. Screenshot that yourself. This install does not restart the TV.

## Remote buttons, with the helpers left off

On the G08 remote described in the device note, while this launcher is the focused window:

| Button | What this build does |
|---|---|
| Gear (keycode 83) | Opens Settings |
| Netflix (4062) | Opens Netflix |
| Prime Video (4099) | Opens Prime Video |
| YouTube (190) | Nothing from this launcher |

YouTube's button needs `InputKeyService`. On this board a key-filtering accessibility service stops a held volume key from ramping, one step per press. Both helpers stay off. Do not pass `-InputKeyService` or `-HomeKeyService` on the other install script until you choose that trade.

## Change the dock later

Edit `dock_apps` and `columns` in `launcher/app/src/main/res/values/config.xml`, build again, and run `install-only.ps1` again. Replacing the APK does not change which app the Home button opens.

After the app is installed, a folder of your own (not a folder under `themes/` or `examples/`) can overlay the same keys. `config.json` with `"dock_apps"` and `"columns"`, then:

```powershell
powershell -ExecutionPolicy Bypass -File tools\theme.ps1 -TvHost 192.168.1.50 C:\my-theme
```

That push restarts this launcher. While the stock launcher still owns the Home button, the restart opens this app on screen and does not change the default. Undo with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\theme.ps1 -TvHost 192.168.1.50 -Reset
```

## Wallpaper

This build draws pitch black and no picture, which keeps the decode off a set with about 1 GB of RAM. There is no `wallpaper.jpg` in the APK.

To add one later, put a dark 1920×1080 JPEG under about 300 KB in a folder you own, next to a `config.json` of `{"wallpaper": true}`, and push that folder with the theme command above. Launcher settings on the TV can then pick a picture from a collection, or None. `wallpaper_true_color` stays off (4 MB decode instead of 8 MB).

## Recovery

This install did not turn any package off and did not change Home, so there is no debloat record to replay. The Home button still opens the stock launcher.

To remove the sideloaded app, use Settings → Apps → Home. The package is `com.gathin.tvhome`. [docs/restore.md](../docs/restore.md) says the same: the restore scripts leave this app installed, and Settings → Apps is how it comes off.

Do not turn off `com.google.android.tungsten.setupwraith` while it owns a saved Wi-Fi network. Android deletes that network, including on a set that is using Ethernet. The device note has the check (`dumpsys wifi` and `cname=`) and the order that kept Wi-Fi on the sets it describes. That step is not part of this install.

## What was left for later

Handover, disabling the stock launcher, and disabling setupwraith wait until you choose them, with screenshots, and only after the saved network is not owned by setupwraith. `power_on_home` stays off until you pick Home or Live TV at power-on. Neither choice is set here.

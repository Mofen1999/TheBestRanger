# Project Quarm UI Notes

These notes come from the local EQMacEmu / Project Quarm-style default UI files at `utils/UI/PC/UIFiles/default`.

## File Model

The UI is described by XML files named `EQUI_*.xml`. The root manifest is `EQUI.xml`, which includes shared definitions first, then each window file. In the default set, `EQUI_Animations.xml` and `EQUI_Templates.xml` are the important shared files:

- `EQUI_Animations.xml` declares `TextureInfo` records for bitmap files and `Ui2DAnimation` records that crop pieces out of those textures.
- `EQUI_Templates.xml` groups those animation pieces into reusable draw templates such as `WDT_Def`, `WDT_Def2`, `WDT_Inner`, and `WDT_RoundedNoTitle`.
- Individual windows, such as `EQUI_PlayerWindow.xml` and `EQUI_TrackingWnd.xml`, place controls and choose templates with tags like `<DrawTemplate>WDT_Def2</DrawTemplate>`.

## Image References

The XML references images by filename, usually `.tga` and sometimes `.bmp`. The default XML references common files such as:

- `wnd_bg_dark_rock.tga`
- `wnd_bg_light_rock.tga`
- `window_pieces01.tga`
- `window_pieces02.tga`
- `window_pieces03.tga`
- `window_pieces04.tga`
- `ranger01.tga`
- `ranger02.tga`

Custom UI folders can override art by placing an image with the same filename in the active skin folder. This skin starts from a complete Project Quarm UI file set, then applies a dark green tree bark treatment to the UI chrome textures and adds generated `ranger01.tga` / `ranger02.tga` files because the animation XML references those Ranger class art files.

The bark treatment is applied by `tools/apply-bark-theme.ps1`. It preserves image dimensions and alpha while repainting visible pixels with a dark green bark grain. It intentionally targets interface chrome files such as `window_pieces*.tga`, `classic_pieces*.tga`, `wnd_bg_*rock.tga`, `purple*.tga`, `gauges.tga`, `TargetBox.tga`, cursor textures, book backgrounds, and optional theme assets. Spell icons, item icons, and non-Ranger class atlases are left alone for readability.

## Added XML Files

The reference UI folder did not include `EQUI.xml`. It also omitted several files that the Project Quarm default `EQUI.xml` includes. For the repo package, these were copied from `C:\Everquest\Project_Guarm\TAKPv22\uifiles\default`:

- `EQUI.xml`
- `SIDL.xml`
- `EQUI_QuantityWnd.xml`
- `EQUI_SkillsWindow.xml`
- `EQUI_GiveWnd.xml`
- `EQUI_SocialEditWnd.xml`
- `EQUI_HelpWnd.xml`
- `EQUI_BugReportWnd.xml`
- `EQUI_ColorPickerWnd.xml`
- `EQUI_MusicPlayerWnd.xml`
- `EQUI_FileSelectionWnd.xml`

## XML Windows Edited First

`EQUI_PlayerWindow.xml` is a compact, high-value Ranger target because it owns the player gauges:

- HP uses `EQType 1`.
- Mana uses `EQType 2`.
- Stamina / fatigue uses `EQType 3`.
- Pet HP uses `EQType 16`.

`EQUI_TrackingWnd.xml` is also Ranger-specific in spirit. Its list uses `WDT_Inner`, while the outer screen originally used `WDT_Def`. This skin switches the outer screen to `WDT_Def2` so it picks up the darker background feel.

## Theme Direction

The visual direction is "deep in the woods":

- Moss, bark, and shadow in the panel backgrounds.
- Muted gold text instead of stark white where readability allows.
- Earthy red for health, moonlit teal-blue for mana, amber for stamina, and living green for pet health.
- Ranger tracking language where the client-facing labels are safe to rename.

## Next Good Targets

Good next XML targets for this skin:

- `EQUI_TargetWindow.xml` for a matching target gauge.
- `EQUI_GroupWindow.xml` for party HP bars.
- `EQUI_BuffWindow.xml` and `EQUI_ShortDurationBuffWindow.xml` for buff icon frame spacing.
- A carefully mapped `window_pieces01.tga` replacement once the exact atlas slices are documented.

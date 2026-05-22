# TheBestRanger

Project Quarm / EverQuest custom UI skin for Rangers.

The first playable package is in `UIFiles/TheBestRanger`. It starts with a deep woods theme: dark moss window backgrounds, warmer parchment-style label colors, Ranger-tuned player gauge colors, a themed tracking window title, and custom Ranger class art textures.

## Install

1. Copy `UIFiles/TheBestRanger` into your Project Quarm `uifiles` folder.
2. In game, run `/loadskin TheBestRanger`.
3. If the client warns about an XML problem, use `/loadskin default` and compare against the notes in `docs/project-quarm-ui-notes.md`.

## Contents

- `UIFiles/TheBestRanger/EQUI_PlayerWindow.xml` - Ranger-colored health, mana, stamina, and pet gauges.
- `UIFiles/TheBestRanger/EQUI_TrackingWnd.xml` - darker tracking window with Ranger-themed labels.
- `UIFiles/TheBestRanger/*.tga` - generated forest textures used by the stock XML image names.
- `tools/generate-ranger-assets.ps1` - rebuilds the TGA files from source.
- `docs/project-quarm-ui-notes.md` - notes on how the XML and image files work together.

## Rebuild Art

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\generate-ranger-assets.ps1
```

The generated images intentionally keep the same filenames that the default XML already references, such as `wnd_bg_dark_rock.tga` and `wnd_bg_light_rock.tga`, so the skin can override art without rewriting every window definition.

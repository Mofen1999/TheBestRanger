# TheBestRanger

Project Quarm / EverQuest custom UI skin for Rangers.

The playable package is in `UIFiles/TheBestRanger`. It uses a complete Project Quarm UI file set, with the missing default XML files added so the package is self-contained. The Ranger theme starts with dark moss window backgrounds and custom Ranger class art textures.

## Install

1. Copy `UIFiles/TheBestRanger` into your Project Quarm `uifiles` folder, or unzip `dist/TheBestRanger.zip` into `uifiles`.
2. In game, run `/loadskin TheBestRanger`.
3. If the client warns about an XML problem, use `/loadskin default` and compare against the notes in `docs/project-quarm-ui-notes.md`.

## Contents

- `UIFiles/TheBestRanger/EQUI.xml` - root include manifest copied from the Project Quarm default UI.
- `UIFiles/TheBestRanger/EQUI_*.xml` - Project Quarm UI XML plus default fallback XML files needed by the manifest.
- `UIFiles/TheBestRanger/*.tga` - UI art plus generated Ranger forest textures and class art.
- `dist/TheBestRanger.zip` - ready-to-copy zip package.
- `tools/generate-ranger-assets.ps1` - rebuilds the TGA files from source.
- `docs/project-quarm-ui-notes.md` - notes on how the XML and image files work together.

## Rebuild Art

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\generate-ranger-assets.ps1
```

The generated images intentionally keep filenames already referenced by the XML, such as `wnd_bg_dark_rock.tga`, `wnd_bg_light_rock.tga`, `ranger01.tga`, and `ranger02.tga`, so the skin can override art without rewriting every window definition.

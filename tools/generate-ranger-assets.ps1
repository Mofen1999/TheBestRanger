param(
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\UIFiles\TheBestRanger")
)

$ErrorActionPreference = "Stop"

function Get-Noise {
    param([int]$X, [int]$Y, [int]$Seed)

    $v = [math]::Sin($X * 12.9898 + $Y * 78.233 + $Seed * 37.719)
    return [int]([math]::Floor(($v - [math]::Floor($v)) * 256))
}

function Write-Tga {
    param(
        [string]$Path,
        [int]$Width,
        [int]$Height,
        [scriptblock]$Pixel
    )

    $header = [byte[]]::new(18)
    $header[2] = 2
    $header[12] = [byte]($Width -band 255)
    $header[13] = [byte](($Width -shr 8) -band 255)
    $header[14] = [byte]($Height -band 255)
    $header[15] = [byte](($Height -shr 8) -band 255)
    $header[16] = 32
    $header[17] = 40

    $data = [byte[]]::new($Width * $Height * 4)
    $i = 0
    for ($y = 0; $y -lt $Height; $y++) {
        for ($x = 0; $x -lt $Width; $x++) {
            $rgba = & $Pixel $x $y $Width $Height
            $data[$i++] = [byte]$rgba[2]
            $data[$i++] = [byte]$rgba[1]
            $data[$i++] = [byte]$rgba[0]
            $data[$i++] = [byte]$rgba[3]
        }
    }

    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [System.IO.File]::WriteAllBytes($Path, $header + $data)
}

function New-ForestPixel {
    param(
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [int[]]$Base,
        [int]$Seed,
        [double]$Light
    )

    $grain = Get-Noise $X $Y $Seed
    $moss = Get-Noise ([int]($X / 3)) ([int]($Y / 5)) ($Seed + 29)
    $root = [math]::Sin(($X + $Y * 0.45) / 13.0) * 14
    $leafVein = if ((($X + ($Y * 2)) % 43) -lt 2) { 18 } else { 0 }
    $shade = (($grain - 128) * 0.20) + (($moss - 128) * 0.11) + $root + $leafVein

    $r = [math]::Max(0, [math]::Min(255, ($Base[0] + $shade) * $Light))
    $g = [math]::Max(0, [math]::Min(255, ($Base[1] + $shade * 1.35) * $Light))
    $b = [math]::Max(0, [math]::Min(255, ($Base[2] + $shade * 0.70) * $Light))
    return @([int]$r, [int]$g, [int]$b, 255)
}

function New-RangerPanelPixel {
    param([int]$X, [int]$Y, [int]$W, [int]$H, [int]$Seed)

    $bg = New-ForestPixel $X $Y $W $H @(24, 46, 31) $Seed 1.0
    $cx = $W / 2
    $cy = $H / 2
    $dx = $X - $cx
    $dy = $Y - $cy
    $dist = [math]::Sqrt($dx * $dx + $dy * $dy)

    if ($dist -gt 92 -and $dist -lt 99) {
        return @(121, 91, 47, 255)
    }

    $bow = [math]::Abs($dist - 70) - [math]::Abs($dx) * 0.07
    if ($X -gt 61 -and $X -lt 195 -and $Y -gt 55 -and $Y -lt 201 -and $bow -gt -1.6 -and $bow -lt 2.4 -and $dx -gt -62) {
        return @(156, 111, 55, 255)
    }

    $stringX = [int]($cx - 45 + ($Y - 45) * 0.36)
    if ([math]::Abs($X - $stringX) -lt 1 -and $Y -gt 47 -and $Y -lt 209) {
        return @(205, 190, 146, 255)
    }

    $arrowY = [int]($cy + [math]::Sin($X / 11.0) * 2)
    if ($X -gt 46 -and $X -lt 214 -and [math]::Abs($Y - $arrowY) -lt 2) {
        return @(178, 158, 112, 255)
    }

    if ($X -gt 197 -and $X -lt 218 -and [math]::Abs($Y - $arrowY) -lt (218 - $X) / 3) {
        return @(109, 147, 84, 255)
    }

    return $bg
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Tga (Join-Path $OutputDir "wnd_bg_dark_rock.tga") 256 256 {
    param($x, $y, $w, $h)
    New-ForestPixel $x $y $w $h @(14, 31, 23) 1999 0.88
}

Write-Tga (Join-Path $OutputDir "wnd_bg_light_rock.tga") 256 256 {
    param($x, $y, $w, $h)
    New-ForestPixel $x $y $w $h @(44, 68, 42) 2026 1.04
}

Write-Tga (Join-Path $OutputDir "ranger01.tga") 256 256 {
    param($x, $y, $w, $h)
    New-RangerPanelPixel $x $y $w $h 47
}

Write-Tga (Join-Path $OutputDir "ranger02.tga") 256 256 {
    param($x, $y, $w, $h)
    $p = New-RangerPanelPixel $x $y $w $h 88
    $p[0] = [math]::Min(255, [int]($p[0] * 0.82 + 24))
    $p[1] = [math]::Min(255, [int]($p[1] * 0.90 + 18))
    $p[2] = [math]::Min(255, [int]($p[2] * 0.78 + 14))
    $p
}

Write-Host "Generated Ranger UI TGA assets in $OutputDir"

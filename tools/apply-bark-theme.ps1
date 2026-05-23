param(
    [string]$UiDir = (Join-Path $PSScriptRoot "..\UIFiles\TheBestRanger")
)

$ErrorActionPreference = "Stop"

function Get-Noise {
    param([int]$X, [int]$Y, [int]$Seed)

    $v = [math]::Sin($X * 12.9898 + $Y * 78.233 + $Seed * 37.719)
    return [int]([math]::Floor(($v - [math]::Floor($v)) * 256))
}

function Get-BarkPixel {
    param(
        [int]$X,
        [int]$Y,
        [int]$R,
        [int]$G,
        [int]$B,
        [int]$A,
        [int]$Seed
    )

    if ($A -le 5) {
        return @($R, $G, $B, $A)
    }

    $luma = ($R * 0.299 + $G * 0.587 + $B * 0.114) / 255.0
    $rings = [math]::Sin(($X * 0.075) + ([math]::Sin($Y * 0.061) * 1.8) + $Seed) * 28
    $grain = (Get-Noise $X $Y $Seed) - 128
    $moss = (Get-Noise ([int]($X / 4)) ([int]($Y / 9)) ($Seed + 31)) - 128
    $groove = if ((($X + [int]($Y * 0.35) + $Seed) % 37) -lt 3) { -34 } else { 0 }
    $highlight = if ((($X * 3 + $Y + $Seed) % 83) -lt 2) { 24 } else { 0 }
    $shade = (($luma - 0.48) * 96) + $rings + ($grain * 0.18) + ($moss * 0.15) + $groove + $highlight

    $nr = [math]::Max(0, [math]::Min(255, 24 + $shade * 0.42))
    $ng = [math]::Max(0, [math]::Min(255, 54 + $shade * 0.72))
    $nb = [math]::Max(0, [math]::Min(255, 30 + $shade * 0.35))

    if ($luma -gt 0.72) {
        $nr = [math]::Min(255, $nr + 18)
        $ng = [math]::Min(255, $ng + 34)
        $nb = [math]::Min(255, $nb + 17)
    }

    return @([int]$nr, [int]$ng, [int]$nb, $A)
}

function Read-TgaPixels {
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 18) {
        throw "TGA too short: $Path"
    }

    $idLength = [int]$bytes[0]
    $type = [int]$bytes[2]
    $width = [int]$bytes[12] + ([int]$bytes[13] -shl 8)
    $height = [int]$bytes[14] + ([int]$bytes[15] -shl 8)
    $bits = [int]$bytes[16]
    $descriptor = [int]$bytes[17]
    $channels = [int]($bits / 8)
    if (($type -ne 2 -and $type -ne 10) -or ($bits -ne 24 -and $bits -ne 32)) {
        throw "Unsupported TGA type=$type bits=$bits in $Path"
    }

    $count = $width * $height
    $pixels = New-Object 'byte[]' ($count * 4)
    $src = 18 + $idLength
    $dstPixel = 0

    if ($type -eq 2) {
        while ($dstPixel -lt $count) {
            $b = $bytes[$src++]
            $g = $bytes[$src++]
            $r = $bytes[$src++]
            $a = if ($channels -eq 4) { $bytes[$src++] } else { 255 }
            $i = $dstPixel * 4
            $pixels[$i] = $r
            $pixels[$i + 1] = $g
            $pixels[$i + 2] = $b
            $pixels[$i + 3] = $a
            $dstPixel++
        }
    } else {
        while ($dstPixel -lt $count) {
            $packet = [int]$bytes[$src++]
            $run = ($packet -band 127) + 1
            if (($packet -band 128) -ne 0) {
                $b = $bytes[$src++]
                $g = $bytes[$src++]
                $r = $bytes[$src++]
                $a = if ($channels -eq 4) { $bytes[$src++] } else { 255 }
                for ($j = 0; $j -lt $run; $j++) {
                    $i = $dstPixel * 4
                    $pixels[$i] = $r
                    $pixels[$i + 1] = $g
                    $pixels[$i + 2] = $b
                    $pixels[$i + 3] = $a
                    $dstPixel++
                }
            } else {
                for ($j = 0; $j -lt $run; $j++) {
                    $b = $bytes[$src++]
                    $g = $bytes[$src++]
                    $r = $bytes[$src++]
                    $a = if ($channels -eq 4) { $bytes[$src++] } else { 255 }
                    $i = $dstPixel * 4
                    $pixels[$i] = $r
                    $pixels[$i + 1] = $g
                    $pixels[$i + 2] = $b
                    $pixels[$i + 3] = $a
                    $dstPixel++
                }
            }
        }
    }

    return @{
        Width = $width
        Height = $height
        Pixels = $pixels
        TopOrigin = (($descriptor -band 32) -ne 0)
    }
}

function Write-TgaPixels {
    param(
        [string]$Path,
        [int]$Width,
        [int]$Height,
        [byte[]]$Pixels
    )

    $header = New-Object 'byte[]' 18
    $header[2] = 2
    $header[12] = [byte]($Width -band 255)
    $header[13] = [byte](($Width -shr 8) -band 255)
    $header[14] = [byte]($Height -band 255)
    $header[15] = [byte](($Height -shr 8) -band 255)
    $header[16] = 32
    $header[17] = 40

    $data = New-Object 'byte[]' ($Width * $Height * 4)
    $di = 0
    for ($i = 0; $i -lt $Pixels.Length; $i += 4) {
        $data[$di++] = $Pixels[$i + 2]
        $data[$di++] = $Pixels[$i + 1]
        $data[$di++] = $Pixels[$i]
        $data[$di++] = $Pixels[$i + 3]
    }

    [System.IO.File]::WriteAllBytes($Path, $header + $data)
}

function Apply-BarkToTga {
    param([string]$Path, [int]$Seed)

    $image = Read-TgaPixels $Path
    $pixels = $image.Pixels
    $width = $image.Width
    $height = $image.Height

    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $i = (($y * $width) + $x) * 4
            $p = Get-BarkPixel $x $y $pixels[$i] $pixels[$i + 1] $pixels[$i + 2] $pixels[$i + 3] $Seed
            $pixels[$i] = [byte]$p[0]
            $pixels[$i + 1] = [byte]$p[1]
            $pixels[$i + 2] = [byte]$p[2]
            $pixels[$i + 3] = [byte]$p[3]
        }
    }

    Write-TgaPixels $Path $width $height $pixels
}

function Apply-BarkToBitmap {
    param([string]$Path, [int]$Seed)

    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::new($Path)
    try {
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $c = $bitmap.GetPixel($x, $y)
                $p = Get-BarkPixel $x $y $c.R $c.G $c.B $c.A $Seed
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($p[3], $p[0], $p[1], $p[2]))
            }
        }
        $format = if ([System.IO.Path]::GetExtension($Path).ToLowerInvariant() -eq ".bmp") {
            [System.Drawing.Imaging.ImageFormat]::Bmp
        } else {
            [System.Drawing.Imaging.ImageFormat]::Png
        }
        $tmp = "$Path.barktmp"
        if (Test-Path -LiteralPath $tmp) {
            Remove-Item -LiteralPath $tmp -Force
        }
        $bitmap.Save($tmp, $format)
    } finally {
        $bitmap.Dispose()
    }

    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

$texturePatterns = @(
    "AttackIndicator.tga",
    "background_*.tga",
    "Buff_Background.tga",
    "classic_pieces*.tga",
    "CS_Buttons.bmp",
    "Custom_Cursor*.tga",
    "dzbars*.png",
    "dzbuttons*.png",
    "gauges.tga",
    "purple*.tga",
    "ranger*.tga",
    "scrollbar_gutter.tga",
    "smallbook*.png",
    "spellbook*.tga",
    "TargetBox.tga",
    "window_pieces*.tga",
    "wnd_bg_*rock.tga"
)

$files = foreach ($pattern in $texturePatterns) {
    Get-ChildItem -Path $UiDir -Recurse -File -Filter $pattern
}

$unique = $files | Sort-Object FullName -Unique
$i = 0
foreach ($file in $unique) {
    $i++
    $seed = 1103 + ($i * 17)
    switch ($file.Extension.ToLowerInvariant()) {
        ".tga" { Apply-BarkToTga $file.FullName $seed }
        ".png" { Apply-BarkToBitmap $file.FullName $seed }
        ".bmp" { Apply-BarkToBitmap $file.FullName $seed }
    }
    Write-Host "Bark themed $($file.FullName)"
}

Write-Host "Applied dark green bark theme to $($unique.Count) interface texture files."

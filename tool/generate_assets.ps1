Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $root "assets\icon"
$web = Join-Path $root "web"
New-Item -ItemType Directory -Force -Path $assets | Out-Null

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    if ($r -le 0) {
        $p.AddRectangle((New-Object System.Drawing.RectangleF($x, $y, $w, $h)))
        return $p
    }
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-PointArray([object[]]$pairs) {
    $pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for ($i = 0; $i -lt $pairs.Count; $i += 2) {
        $pts.Add((New-Object System.Drawing.PointF([float]$pairs[$i], [float]$pairs[$i + 1])))
    }
    return $pts.ToArray()
}

function Draw-Car([System.Drawing.Graphics]$g, [float]$scale, [float]$offsetX, [float]$offsetY) {
    $state = $g.Save()
    $g.TranslateTransform($offsetX, $offsetY)
    $g.ScaleTransform($scale, $scale)

    $amber = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(200, 380)),
        (New-Object System.Drawing.PointF(820, 720)),
        [System.Drawing.Color]::FromArgb(255, 255, 190, 60),
        [System.Drawing.Color]::FromArgb(255, 240, 138, 0))
    $dark = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 15, 22, 30))
    $glass = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 26, 38, 50))
    $tire = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 8, 12, 17))
    $rim = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 201, 212, 224))
    $hub = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 176, 32))
    $light = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 232, 170))

    $body = New-PointArray @(
        170, 620,
        178, 566,
        206, 534,
        268, 522,
        330, 500,
        372, 430,
        430, 396,
        560, 390,
        660, 408,
        716, 458,
        754, 520,
        846, 544,
        876, 580,
        872, 636,
        850, 666,
        790, 676,
        760, 650,
        700, 648,
        680, 676,
        620, 676,
        600, 648,
        420, 648,
        400, 676,
        340, 676,
        320, 648,
        240, 648,
        212, 668,
        176, 654
    )
    $g.FillPolygon($amber, $body)

    $cabin = New-PointArray @(
        368, 508,
        408, 444,
        452, 418,
        556, 414,
        638, 430,
        690, 476,
        712, 516
    )
    $g.FillPolygon($glass, $cabin)

    $windowSplit = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 15, 22, 30), 14)
    $g.DrawLine($windowSplit, 540, 416, 540, 514)

    $g.FillEllipse($tire, 240, 596, 178, 178)
    $g.FillEllipse($tire, 610, 596, 178, 178)
    $g.FillEllipse($rim, 282, 638, 94, 94)
    $g.FillEllipse($rim, 652, 638, 94, 94)
    $g.FillEllipse($hub, 316, 672, 26, 26)
    $g.FillEllipse($hub, 686, 672, 26, 26)

    $g.FillEllipse($light, 806, 566, 54, 26)

    $shine = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 255, 255, 255), 10)
    $g.DrawLine($shine, 214, 566, 330, 546)

    $windowSplit.Dispose()
    $shine.Dispose()
    $amber.Dispose(); $dark.Dispose(); $glass.Dispose(); $tire.Dispose(); $rim.Dispose(); $hub.Dispose(); $light.Dispose()
    $g.Restore($state)
}

function Draw-Journal([System.Drawing.Graphics]$g) {
    $state = $g.Save()
    $g.TranslateTransform(196, 190)
    $g.RotateTransform(-9)

    $shadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))
    $shadowPath = New-RoundedPath 10 14 214 176 26
    $g.FillPath($shadow, $shadowPath)

    $paper = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(210, 176)),
        [System.Drawing.Color]::FromArgb(255, 250, 252, 255),
        [System.Drawing.Color]::FromArgb(255, 220, 229, 238))
    $paperPath = New-RoundedPath 0 0 214 176 26
    $g.FillPath($paper, $paperPath)

    $line = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 176, 32), 12)
    $line.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $line.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($line, 34, 54, 154, 54)
    $g.DrawLine($line, 34, 92, 178, 92)
    $g.DrawLine($line, 34, 130, 132, 130)

    $check = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 26, 38, 50), 13)
    $check.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $check.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLines($check, (New-PointArray @(34, 148, 52, 166, 92, 120)))

    $check.Dispose(); $line.Dispose(); $paper.Dispose(); $shadow.Dispose()
    $g.Restore($state)
}

function New-Icon([int]$size, [string]$path, [bool]$rounded) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $scale = $size / 1024.0
    $g.ScaleTransform($scale, $scale)

    if ($rounded) {
        $bgPath = New-RoundedPath 0 0 1024 1024 214
    } else {
        $bgPath = New-RoundedPath 0 0 1024 1024 0
    }
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(1024, 1024)),
        [System.Drawing.Color]::FromArgb(255, 16, 24, 32),
        [System.Drawing.Color]::FromArgb(255, 34, 48, 63))
    $g.FillPath($bg, $bgPath)

    $glow = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glow.AddEllipse(140, 320, 744, 420)
    $glowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow)
    $glowBrush.CenterColor = [System.Drawing.Color]::FromArgb(60, 255, 176, 32)
    $glowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 176, 32))
    $g.FillPath($glowBrush, $glow)

    $road = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 44, 60, 76), 18)
    $road.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $road.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($road, 132, 812, 892, 812)
    $dash = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 176, 32), 14)
    $dash.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $dash.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($dash, 250, 812, 330, 812)
    $g.DrawLine($dash, 470, 812, 550, 812)
    $g.DrawLine($dash, 690, 812, 770, 812)

    Draw-Car $g 0.86 62 106
    Draw-Journal $g

    $road.Dispose(); $dash.Dispose(); $glowBrush.Dispose(); $glow.Dispose(); $bg.Dispose(); $bgPath.Dispose()
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function New-Foreground([string]$path) {
    $size = 1024
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.ScaleTransform(0.72, 0.72)
    $g.TranslateTransform(199, 199)
    Draw-Car $g 0.78 90 150
    Draw-Journal $g
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function New-Splash([string]$path) {
    $size = 1200
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    $logo = New-Object System.Drawing.Bitmap(600, 600)
    $lg = [System.Drawing.Graphics]::FromImage($logo)
    $lg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $lg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $lg.Clear([System.Drawing.Color]::Transparent)
    $lg.ScaleTransform(600 / 1024.0, 600 / 1024.0)
    $bgPath = New-RoundedPath 0 0 1024 1024 214
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.PointF(0, 0)),
        (New-Object System.Drawing.PointF(1024, 1024)),
        [System.Drawing.Color]::FromArgb(255, 16, 24, 32),
        [System.Drawing.Color]::FromArgb(255, 34, 48, 63))
    $lg.FillPath($bg, $bgPath)
    $glow = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glow.AddEllipse(140, 320, 744, 420)
    $glowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow)
    $glowBrush.CenterColor = [System.Drawing.Color]::FromArgb(60, 255, 176, 32)
    $glowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 176, 32))
    $lg.FillPath($glowBrush, $glow)
    $road = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 44, 60, 76), 18)
    $road.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $road.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $lg.DrawLine($road, 132, 812, 892, 812)
    $dash = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 176, 32), 14)
    $dash.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $dash.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $lg.DrawLine($dash, 250, 812, 330, 812)
    $lg.DrawLine($dash, 470, 812, 550, 812)
    $lg.DrawLine($dash, 690, 812, 770, 812)
    Draw-Car $lg 0.86 62 106
    Draw-Journal $lg
    $lg.Dispose()

    $g.DrawImage($logo, 300, 90, 600, 600)

    $titleFont = New-Object System.Drawing.Font("Segoe UI", 78, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $subFont = New-Object System.Drawing.Font("Segoe UI", 34, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 247, 250, 253))
    $subBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 159, 176, 192))
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString("MyCarJournal", $titleFont, $titleBrush, (New-Object System.Drawing.PointF(600, 726)), $fmt)
    $g.DrawString("Щоденник автомобіліста", $subFont, $subBrush, (New-Object System.Drawing.PointF(600, 836)), $fmt)

    $titleFont.Dispose(); $subFont.Dispose(); $titleBrush.Dispose(); $subBrush.Dispose(); $logo.Dispose()
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

New-Icon 1024 (Join-Path $assets "icon.png") $true
New-Icon 1024 (Join-Path $assets "icon_full.png") $false
New-Foreground (Join-Path $assets "icon_foreground.png")
New-Splash (Join-Path $assets "splash.png")
New-Icon 512 (Join-Path $web "icons\Icon-512.png") $true
New-Icon 192 (Join-Path $web "icons\Icon-192.png") $true
New-Icon 512 (Join-Path $web "icons\Icon-maskable-512.png") $false
New-Icon 192 (Join-Path $web "icons\Icon-maskable-192.png") $false
New-Icon 64 (Join-Path $web "favicon.png") $true

Write-Output "Assets generated:"
Get-ChildItem $assets, (Join-Path $web "icons") | Select-Object FullName, Length

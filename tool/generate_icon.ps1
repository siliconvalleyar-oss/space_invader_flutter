Add-Type -AssemblyName System.Drawing

function Create-Icon {
    param([int]$size, [string]$path)
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'HighQuality'
    
    # Background - transparent
    $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
    
    # Draw spaceship triangle (dark green)
    $green = [System.Drawing.Color]::FromArgb(255, 0, 200, 100)
    $brush = New-Object System.Drawing.SolidBrush($green)
    
    $p1 = New-Object System.Drawing.PointF($size/2, $size*0.1)
    $p2 = New-Object System.Drawing.PointF($size*0.85, $size*0.85)
    $p3 = New-Object System.Drawing.PointF($size*0.15, $size*0.85)
    $pts = @($p1, $p2, $p3)
    $g.FillPolygon($brush, $pts)
    
    # Cockpit (lighter green)
    $lightGreen = [System.Drawing.Color]::FromArgb(255, 100, 255, 180)
    $cBrush = New-Object System.Drawing.SolidBrush($lightGreen)
    $g.FillEllipse($cBrush, $size*0.4, $size*0.3, $size*0.2, $size*0.15)
    
    # Engine glow (orange)
    $orange = [System.Drawing.Color]::FromArgb(255, 255, 150, 0)
    $oBrush = New-Object System.Drawing.SolidBrush($orange)
    $g.FillRectangle($oBrush, $size*0.35, $size*0.8, $size*0.3, $size*0.1)
    
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$projectDir = "flutter/space_invaders/android/app/src/main/res"
$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($dir in $sizes.Keys) {
    $fullPath = Join-Path $projectDir $dir "ic_launcher.png"
    Write-Host "Generating $fullPath ($($sizes[$dir])x$($sizes[$dir]))"
    Create-Icon -size $sizes[$dir] -path $fullPath
}

Write-Host "All icons generated successfully!"

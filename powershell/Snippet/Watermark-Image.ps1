$FontName = "Segoe UI"
$FontSize = 12
$FontColor = @(255, 255, 255)
$OutFile = 'E:\Temp\BGInfo.bmp'




# get path to current wallpaper
$WallPaperPath = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction Stop).WallPaper

if ($WallpaperPath.Length -eq 0) {
    "solid color"
    $UseCurrentWallpaperAsSource = $false
    $color = (Get-ItemProperty 'HKCU:\Control Panel\Colors' -ErrorAction Stop).BackGround
}
else {
    "wallpaper"
    $UseCurrentWallpaperAsSource = $true
}

$UseCurrentWallpaperAsSource

try {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    # Draw string > alignement
    $StringFormat = New-Object System.Drawing.StringFormat
    $StringFormat.Alignment = 'Far'
    $StringFormat.LineAlignment = 'Near'

    if ($UseCurrentWallpaperAsSource) {
        if (Test-Path -Path $WallpaperPath -PathType Leaf) {

            # creates new image from current wallpaper and gets size
            $bitmap = New-Object System.Drawing.Bitmap -ArgumentList $WallPaperPath
            $image = [System.Drawing.Graphics]::FromImage($bitmap)
            $screen = $bitmap | Select-Object Width, Height
        }
        else {
            "Cant find current wallpaper"
            exit
        }
    }
    else {
        # gets screen size
        $screen = [System.Windows.Forms.Screen]::AllScreens | Where-Object Primary | Select-Object -ExpandProperty Bounds | Select-Object Width, Height

        # creates a new empty image
        $Bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Width)
        $Image = [System.Drawing.Graphics]::FromImage($bitmap)

        # fills the image with the current color
        $Image.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($color[0], $color[1], $color[2]))), (New-Object System.Drawing.Rectangle(0, 0, $screen.Width, $screen.Height)))
        
    }

    $text = @(
        "Computername: $env:COMPUTERNAME",
        "Username: $env:USERNAME",
        "System Start Time : $(Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime)"
    )
    foreach ($line in $text) {
        # sets font, size, and color
        $Font = New-Object System.Drawing.Font($FontName, $FontSize, [System.Drawing.FontStyle]::Bold)
        $WhiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($FontColor[0], $FontColor[1], $FontColor[2]))
        $Size = [System.Windows.Forms.TextRenderer]::MeasureText($item, $Font)
        $Rectangle = New-Object System.Drawing.RectangleF(0, ($text.IndexOf($line) * $FontSize * 1.5 + $Size.Height) , $screen.Width, $screen.Height)
        $Image.DrawString($line, $Font, $WhiteBrush, $Rectangle, $StringFormat)
    }

    $image.Dispose()

    $bitmap.Save($Outfile, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bitmap.Dispose()

    Get-Item -Path $OutFile
    # Invoke-Item $OutFile
    
    $Style = 'Stretch'
    [Wallpaper.Setter]::SetWallpaper( $OutFile, $Style )









}
catch {
    $_.Exception.Message
}
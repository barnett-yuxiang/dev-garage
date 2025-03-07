#!/bin/bash

# ========================================================
# Image Format Detection Script
# --------------------------------------------------------
# This script checks if a file is an image and determines its format.
# Supported image formats:
#   - PNG
#   - JPEG/JPG
#   - GIF
#   - BMP
#   - TIFF
#   - WebP
#   - ICO
#   - PSD (Photoshop)
#   - AVIF
#   - HEIC/HEIF
#   - SVG
# ========================================================

# Check if a file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' does not exist."
    exit 1
fi

# Check if xxd command is available
if ! command -v xxd &> /dev/null; then
    echo "Error: 'xxd' command not found. Please install it."
    exit 1
fi

# Read the file signatures for comparison
# For some formats we need different byte lengths
signature_8=$(xxd -p -l 8 "$1" 2>/dev/null)
signature_4=$(xxd -p -l 4 "$1" 2>/dev/null)
signature_2=$(xxd -p -l 2 "$1" 2>/dev/null)
signature_6=$(xxd -p -l 6 "$1" 2>/dev/null)  # Added for GIF detection

# Check if xxd command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to read file signature."
    exit 1
fi

# Define image file signatures (hex)
png_signature="89504e470d0a1a0a"       # PNG: 89 50 4E 47 0D 0A 1A 0A
jpeg_signatures=("ffd8ffe0" "ffd8ffe1" "ffd8ffe2" "ffd8ffe3" "ffd8fffe") # JPEG/JPG variations
gif_signatures=("474946383761" "474946383961")   # GIF87a and GIF89a
bmp_signature="424d"                   # BMP: 42 4D (BM)
webp_signature_partial="57454250"      # WEBP: contains "WEBP" after RIFF header
tiff_signatures=("49492a00" "4d4d002a")  # TIFF: Little/Big endian variations
ico_signature="00000100"               # ICO: 00 00 01 00
psd_signature="38425053"               # PSD: 8BPS
avif_signature_partial="66747970617669" # AVIF: ftyp + avif
heic_signature_partial="66747970686569" # HEIC: ftyp + heic/heix

# Function to check if a string starts with any of the patterns in an array
starts_with_any() {
    local string=$1
    shift
    local patterns=("$@")

    for pattern in "${patterns[@]}"; do
        if [[ $string == $pattern* ]]; then
            return 0
        fi
    done

    return 1
}

# Check for WebP specifically (has RIFF header + WEBP)
check_webp() {
    local riff_check=$(xxd -p -l 4 "$1" 2>/dev/null)
    if [[ "$riff_check" == "52494646" ]]; then  # "RIFF" signature
        local webp_check=$(xxd -p -s 8 -l 4 "$1" 2>/dev/null)
        if [[ "$webp_check" == "$webp_signature_partial" ]]; then
            return 0
        fi
    fi
    return 1
}

# Check for AVIF/HEIC formats (has ftyp box with specific brands)
check_ftyp_format() {
    local format=$1
    local file=$2
    local header=$(xxd -p -l 12 "$file" 2>/dev/null)
    if [[ $header == *"$format"* ]]; then
        return 0
    fi
    return 1
}

# Check if file is SVG (XML with svg tag)
check_svg() {
    if grep -q "<svg" "$1" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Check for each image format
is_image=false

if [ "$signature_8" == "$png_signature" ]; then
    echo "The file is a PNG image."
    is_image=true
elif starts_with_any "$signature_4" "${jpeg_signatures[@]}"; then
    echo "The file is a JPEG/JPG image."
    is_image=true
elif starts_with_any "$signature_6" "${gif_signatures[@]}"; then
    echo "The file is a GIF image."
    is_image=true
elif [ "$signature_2" == "$bmp_signature" ]; then
    echo "The file is a BMP image."
    is_image=true
elif starts_with_any "$signature_4" "${tiff_signatures[@]}"; then
    echo "The file is a TIFF image."
    is_image=true
elif check_webp "$1"; then
    echo "The file is a WebP image."
    is_image=true
elif [ "$signature_4" == "$ico_signature" ]; then
    echo "The file is an ICO image."
    is_image=true
elif [ "$signature_4" == "$psd_signature" ]; then
    echo "The file is a Photoshop PSD image."
    is_image=true
elif check_ftyp_format "$avif_signature_partial" "$1"; then
    echo "The file is an AVIF image."
    is_image=true
elif check_ftyp_format "$heic_signature_partial" "$1"; then
    echo "The file is a HEIC image."
    is_image=true
elif check_svg "$1"; then
    echo "The file is an SVG image."
    is_image=true
else
    echo "The file is NOT a recognized image format."
    is_image=false
fi

# Exit with appropriate code
exit $([ "$is_image" = true ] && echo 0 || echo 1)

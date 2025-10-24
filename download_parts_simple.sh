#!/bin/bash

# Script to download relevant truck parts images from Unsplash

echo "🚛 Truck Parts Image Downloader"
echo "================================="

# Create directory
mkdir -p assets/images/parts

# Array of parts with specific search terms
parts=(
    "GASKETS:engine+gasket+automotive"
    "CONNECTING_BUSH:suspension+bush+automotive"
    "COVER_ASSY:engine+cover+assembly"
    "CONNECTING_BEARING:connecting+rod+bearing"
    "DRAG_LINK:drag+link+steering"
    "VALVE:engine+valve+automotive"
    "DIFFERENTIAL:truck+differential"
    "BRAKE_LINING:brake+lining+truck"
    "CYLINDER_LINER:cylinder+liner+engine"
    "MAIN_BEARING:main+bearing+engine"
    "THRUST_WASHER:thrust+washer+engine"
    "BALL_SUSPENSION:ball+joint+suspension"
    "OILSEALS:oil+seal+automotive"
    "BRAKE_SHOE:brake+shoe+truck"
    "CAM_BUSH:cam+bush+engine"
    "UJCROSS:universal+joint+cross"
    "WHEEL_BEARINGS:wheel+bearing+truck"
    "FILTERS:oil+filter+truck"
    "MAIN_BUSH:main+bush+suspension"
    "DISCPAD:brake+pad+disc"
    "KITSET:repair+kit+automotive"
    "GEARBOX:transmission+truck"
    "ENGINE:truck+engine"
    "PISTON_RING_SET:piston+ring+set"
    "TAPPET_COVER:rocker+cover+engine"
    "PISTON_SET:piston+set+engine"
    "RING_SET:piston+ring+set"
    "UJ_KIT:universal+joint+kit"
    "CLUTCH:clutch+assembly+truck"
    "DRIVE_LINE:driveshaft+truck"
    "GEAR_PARTS:gearbox+parts"
    "FRONT_AXLE:front+axle+truck"
    "MAIN_BEARING_KIT:main+bearing+kit"
    "CLUTCH_PLATE:clutch+plate"
    "SUSPENSION:truck+suspension"
    "BRAKE:air+brake+truck"
    "VR_BUSH:v+mount+bush"
    "COOLING_SYSTEM:radiator+cooling+system"
    "CLUTCH_RELEASE_BEARING:clutch+release+bearing"
    "SLIP_YOKE:slip+yoke+driveshaft"
    "ELECTRICALS:truck+electrical+system"
    "TIE_ROD:tie+rod+steering"
    "IG_BUSH:ignition+bush"
    "MAIN_AND_CR_BRG:main+connecting+rod+bearing"
    "BODYPARTS:truck+body+parts"
    "COOLANT:coolant+system"
    "FLYWHEEL:flywheel+engine"
    "TIE_ROD_REPAIR_KIT:tie+rod+repair+kit"
    "CONNECTING_BEARING_KIT:connecting+rod+bearing+kit"
    "HUB:wheel+hub+truck"
    "SENSORS:engine+sensor"
    "CABLES:cable+automotive"
    "OIL_SUMP:oil+pan+engine"
    "HYDRAULIC_JACK:hydraulic+jack"
    "BALL_SUSPENSION_JOINT:ball+joint+suspension"
    "CENTER_BEARING_RUBBER:center+bearing+rubber"
    "FUEL_INJECTION:fuel+injection+system"
)

echo "📦 Downloading relevant images for ${#parts[@]} parts..."

success_count=0
fail_count=0

# Test network connectivity first
echo "🔍 Testing network connectivity..."
if ! curl -s --max-time 10 -I https://source.unsplash.com > /dev/null; then
    echo "❌ Network connectivity issue detected!"
    echo "💡 Try: ping source.unsplash.com"
    exit 1
fi

for part_entry in "${parts[@]}"; do
    IFS=':' read -r part search_term <<< "$part_entry"
    echo "Processing: $part (Search: $search_term)"
    
    output="assets/images/parts/${part}.jpg"
    
    # Use Unsplash with specific search term
    url="https://source.unsplash.com/400x300/?$search_term"
    
    if curl -L -s --max-time 15 --retry 1 -o "$output" "$url"; then
        if [ -s "$output" ]; then
            echo "✅ Downloaded: $part"
            ((success_count++))
        else
            echo "❌ Empty file: $part"
            rm -f "$output"
            ((fail_count++))
        fi
    else
        echo "❌ Download failed: $part"
        ((fail_count++))
    fi
    
    # Short delay to be respectful to the API
    sleep 1
done

echo ""
echo "🎉 Download complete!"
echo "📊 Results:"
echo "   ✅ Successful: $success_count"
echo "   ❌ Failed: $fail_count"
echo "📁 Images saved to: assets/images/parts/"

# Create a simple HTML file to view all downloaded images
if [ $success_count -gt 0 ]; then
    html_file="assets/images/parts/view_images.html"
    echo "<html><head><title>Downloaded Parts Images</title></head><body>" > "$html_file"
    echo "<h1>Downloaded Parts Images ($success_count files)</h1>" >> "$html_file"
    for part_entry in "${parts[@]}"; do
        IFS=':' read -r part search_term <<< "$part_entry"
        if [ -f "assets/images/parts/${part}.jpg" ]; then
            echo "<div style='margin:10px; padding:10px; border:1px solid #ccc; display:inline-block;'>" >> "$html_file"
            echo "<h3>$part</h3>" >> "$html_file"
            echo "<img src='${part}.jpg' alt='$part' style='width:200px;'/>" >> "$html_file"
            echo "</div>" >> "$html_file"
        fi
    done
    echo "</body></html>" >> "$html_file"
    echo "👀 Preview file created: $html_file"
fi
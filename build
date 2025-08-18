#!/bin/bash

# Default build destination for M4-Besigue
DEFAULT_DESTINATION="platform=iOS Simulator,name=iPad Pro 13-inch (M4)"

# Use provided destination or default
DESTINATION=${1:-$DEFAULT_DESTINATION}

echo "🏗️  Building M4-Besigue for: $DESTINATION"
echo "💡 Tip: Run './build.sh' for iPad Pro 13-inch (M4), or './build.sh \"platform=iOS Simulator,name=iPhone 16 Pro\"' for other devices"

xcodebuild -project M4-Besigue.xcodeproj -scheme M4-Besigue -destination "$DESTINATION" build

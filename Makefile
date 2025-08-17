# M4-Besigue Build Targets
# Run 'make' for default iPad Pro build, or specify target like 'make iphone'

.PHONY: default ipad iphone clean

# Default target - iPad Pro 13-inch (M4)
default: ipad

# Build for iPad Pro 13-inch (M4)
ipad:
	@echo "🏗️  Building for iPad Pro 13-inch (M4)"
	xcodebuild -project M4-Besigue.xcodeproj -scheme M4-Besigue -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build

# Build for iPhone 16 Pro
iphone:
	@echo "🏗️  Building for iPhone 16 Pro"
	xcodebuild -project M4-Besigue.xcodeproj -scheme M4-Besigue -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Clean build
clean:
	@echo "🧹 Cleaning build artifacts"
	xcodebuild -project M4-Besigue.xcodeproj -scheme M4-Besigue clean

# List available simulators
simulators:
	@echo "📱 Available iOS Simulators:"
	xcrun simctl list devices | grep "iPhone\|iPad" | grep -v "unavailable"

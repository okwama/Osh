#!/bin/sh

# Install CocoaPods using Homebrew
brew install cocoapods

# Navigate to iOS directory and install pods
cd ios && pod install

# For Flutter projects, also run:
flutter pub get

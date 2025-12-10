#!/bin/bash

# Clean Flutter build
flutter clean

# Remove iOS pods
rm -rf ios/Pods
rm -rf ios/Podfile.lock

# Install pods with x86_64 only for simulator
cd ios
pod install --repo-update
cd ..

# Get Flutter dependencies
flutter pub get

# Run on iOS Simulator (x86_64 only)
flutter run




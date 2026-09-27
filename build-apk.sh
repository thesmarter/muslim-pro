#!/bin/bash
set -euo pipefail

PATH_PROJECT=$(pwd)

# build apk
flutter build apk --flavor production --release

# Copy the production APK only after a successful build.
cp "$PATH_PROJECT/build/app/outputs/flutter-apk/app-production-release.apk" "$PATH_PROJECT/azkar-app.apk"

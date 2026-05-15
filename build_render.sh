#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
export PATH="$PATH:$(pwd)/flutter/bin"

flutter precache --web
flutter pub get

flutter build web --release --no-tree-shake-icons \
  --dart-define=DEPLOYMENT=$DEPLOYMENT \
  --dart-define=LOCAL=$LOCAL \
  --dart-define=LOCATIONIQ_API_KEY=$LOCATIONIQ_API_KEY \
  --dart-define=MAPTILER_API_KEY=$MAPTILER_API_KEY

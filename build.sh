#!/bin/bash
set -e
echo "=== Installing Flutter SDK for Netlify Deployment ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --branch stable --depth 1 "$HOME/flutter"
fi
export PATH="$PATH:$HOME/flutter/bin"
flutter --version
flutter precache --web
echo "=== Building GebTalk Web Production Release ==="
cd gebtalk_flutter
flutter build web --release
echo "=== Copying SPA Redirects ==="
cp web/_redirects build/web/_redirects || true
echo "=== Build Complete ==="

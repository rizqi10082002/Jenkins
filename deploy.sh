#!/bin/bash

# Pindah ke direktori kerja Jenkins
cd /var/lib/jenkins/workspace/jenkins_testing/ || exit 1

# Hapus dan buat ulang direktori dist
rm -rf dist
mkdir -p dist

echo "=== Minify HTML ==="
find ./ -type f -name "*.html" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
  html-minifier --collapse-whitespace --remove-comments --output "$out" "$file"
done

echo "=== Minify CSS ==="
find ./ -type f -name "*.css" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
  clean-css -o "$out" "$file"
done

echo "=== Minify JS ==="
find ./ -type f -name "*.js" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
  terser "$file" --output "$out"
done

echo "=== Optimasi Gambar ==="
find ./dist -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec jpegoptim --max=80 {} \;

# Testing File Index.html
html-validator --file index.html --verbose || exit 1

echo "=== Linting JS ==="
eslint "./dist/**/*.js" || exit 1

echo "=== Stop & Remove Container Lama ==="
docker stop jenkinsapss 2>/dev/null || true
docker rm jenkinsapss 2>/dev/null || true

echo "=== Build Docker Image ==="
docker build -t jenkins-apps .

echo "=== Jalankan Container di Port 3002 ==="
docker run -d -p 3002:80 --name jenkinsapss jenkins-apps

echo "=== Bersihkan Docker Image Lama ==="
docker image prune -f

echo "✅ DEPLOYMENT SELESAI"

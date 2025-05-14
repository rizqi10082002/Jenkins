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
done

echo "=== Minify JS ==="
find ./ -type f -name "*.js" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
  terser "$file" --output "$out"
done

echo "=== Optimasi Gambar ==="
find ./dist -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec jpegoptim --max=80 {} \;

echo "=== Validasi HTML ==="
status_valid=true

find dist -name "*.html" | while read -r file; do
  echo "Memvalidasi $file..."
  OUTPUT=$(html-validator --file "$file" --validator http://localhost:8888 --verbose 2>&1)
  echo "$OUTPUT"

  if echo "$OUTPUT" | grep -q "Error:"; then
    echo "❌ STATUS: Masih ada ERROR di $file"
    status_valid=false
  elif echo "$OUTPUT" | grep -q "Warning:"; then
    echo "⚠️  STATUS: Ada WARNING di $file. Perlu dicek lagi."
  else
    echo "✅ $file valid."
  fi
done

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

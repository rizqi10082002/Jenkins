#!/bin/bash

echo "# Pindah ke Direktori Job Jenkins #"
cd /var/lib/jenkins/workspace/jenkins_testing/ || exit 1

echo "# Hapus direktori (jika ada) lalu di buat ulang direktori dist #"
rm -rf dist
mkdir -p dist

echo "# Minify file-file html #"
find ./ -type f -name "*.html" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
  html-minifier --collapse-whitespace --remove-comments --output "$out" "$file"
done

echo "# Minify file-file css #"
find ./ -type f -name "*.css" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
done

echo "# Minify file-file js #"
find ./ -type f -name "*.js" | while read -r file; do
  out=./dist/"$file"
  mkdir -p "$(dirname "$out")"
  terser "$file" --output "$out"
done

echo "# Mengoptimasi gambar #"
find ./dist -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec jpegoptim --max=80 {} \;

echo "Validasi index.html"
OUTPUT=$(html-validator --file dist/index.html --validator http://localhost:8888 --verbose 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "Error:"; then
  echo "STATUS: index.html masih ada ERROR. Deployment dibatalkan."
  exit 1
elif echo "$OUTPUT" | grep -q "Warning:"; then
  echo "STATUS: index.html ada WARNING. Perlu dicek lebih lanjut."
else
  echo "STATUS: index.html valid. Tidak ada error atau warning."
fi

echo "# Validasi about.html #"
OUTPUT=$(html-validator --file dist/about.html --validator http://localhost:8888 --verbose 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "Error:"; then
  echo "STATUS: about.html masih ada ERROR. Deployment dibatalkan."
  exit 1
elif echo "$OUTPUT" | grep -q "Warning:"; then
  echo "STATUS: about.html ada WARNING. Perlu dicek lebih lanjut."
else
  echo "STATUS: about.html valid. Tidak ada error atau warning."
fi

echo "# Validasi blog.html #"
OUTPUT=$(html-validator --file dist/blog.html --validator http://localhost:8888 --verbose 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "Error:"; then
  echo "STATUS: blog.html masih ada ERROR. Deployment dibatalkan."
  exit 1
elif echo "$OUTPUT" | grep -q "Warning:"; then
  echo "STATUS: blog.html ada WARNING. Perlu dicek lebih lanjut."
else
  echo "STATUS: blog.html valid. Tidak ada error atau warning."
fi

echo "# Validasi contact.html #"
OUTPUT=$(html-validator --file dist/contact.html --validator http://localhost:8888 --verbose 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "Error:"; then
  echo "STATUS: contact.html masih ada ERROR. Deployment dibatalkan."
  exit 1
elif echo "$OUTPUT" | grep -q "Warning:"; then
  echo "STATUS: contact.html ada WARNING. Perlu dicek lebih lanjut."
else
  echo "STATUS: contact.html valid. Tidak ada error atau warning."
fi

echo "# Validasi shop.html #"
OUTPUT=$(html-validator --file dist/shop.html --validator http://localhost:8888 --verbose 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "Error:"; then
  echo "STATUS: shop.html masih ada ERROR. Deployment dibatalkan."
  exit 1
elif echo "$OUTPUT" | grep -q "Warning:"; then
  echo "STATUS: shop.html ada WARNING. Perlu dicek lebih lanjut."
else
  echo "STATUS: shop.html valid. Tidak ada error atau warning."
fi

echo "& Stop dan Remove Container Lama #"
docker stop jenkinsapss 2>/dev/null || true
docker rm jenkinsapss 2>/dev/null || true

echo "# Build Docker Image #"
docker build -t jenkins-apps .

echo "# Jalankan Container di Port 3002 #"
docker run -d -p 3002:80 --name jenkinsapss jenkins-apps

echo "# Bersihkan Docker Image Lama #"
docker image prune -f

echo "DEPLOYMENT SELESAI DAN BERHASIL"

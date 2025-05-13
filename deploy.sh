#!/bin/bash

# Pindah ke direktori kerja Jenkins
cd /var/lib/jenkins/workspace/jenkins_testing/

# Minify semua file HTML di dalam folder (termasuk subfolder)
find ./ -type f -name "*.html" -exec html-minifier --collapse-whitespace --remove-comments --output ./dist/{} {} \;

# Minify semua file CSS di dalam folder (termasuk subfolder)
find ./ -type f -name "*.css" -exec clean-css -o ./dist/{} {} \;

# Minify semua file JS di dalam folder (termasuk subfolder)
find ./ -type f -name "*.js" -exec terser {} --output ./dist/{} \;

# Salin asset (gambar, font, dll) ke folder dist tanpa diubah
find ./ -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" -o -iname "*.ttf" -o -iname "*.woff" -o -iname "*.woff2" \) -exec cp {} ./dist/{} \;

# Optimasi gambar (contoh pakai imagemagick atau jpegoptim untuk mengurangi ukuran file gambar)
find ./dist -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -exec jpegoptim --max=80 {} \;
find ./dist -type f \( -iname "*.png" \) -exec pngcrush -brute -reduce {} {} \;

# Validasi file HTML setelah minify
html-validator --file ./dist/index.html --verbose || exit 1

# Linting CSS untuk pengecekan kesalahan atau peringatan
stylelint ./dist/**/*.css || exit 1

# Linting JS untuk pengecekan kesalahan atau peringatan
eslint ./dist/**/*.js || exit 1

# Hentikan dan hapus container lama (jika ada)
docker stop jenkinsapss || true
docker rm jenkinsapss || true

# Build ulang Docker image dengan folder dist yang sudah diminyakan dan asset
docker build -t jenkins-apps .

# Jalankan container baru di port 3002
docker run -d -p 3002:80 --name jenkinsapss jenkins-apps

# Bersihkan image lama yang tidak digunakan
docker image prune -f

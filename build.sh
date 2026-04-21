#!/bin/bash

cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alice // Archive</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background-color: #000; color: #efefef; font-family: sans-serif; padding: 5vw; }
        header { text-align: left; margin-bottom: 50px; border-left: 2px solid #333; padding-left: 20px; }
        header h1 { font-size: 2rem; font-weight: 200; letter-spacing: 8px; text-transform: uppercase; color: #fff; }
        header p { font-size: 0.8rem; color: #666; margin-top: 5px; }
        .container { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 25px; }
        .card { background: #080808; border: 1px solid #1a1a1a; border-radius: 4px; overflow: hidden; transition: 0.4s; position: relative; }
        .card:hover { border-color: #444; transform: translateY(-5px); box-shadow: 0 10px 30px rgba(0,0,0,1); }
        .card img { width: 100%; height: 220px; object-fit: cover; filter: grayscale(30%); transition: 0.4s; display: block; }
        .card:hover img { filter: grayscale(0%); }
        .info { padding: 12px; font-size: 0.65rem; font-family: monospace; color: #555; display: flex; justify-content: space-between; text-transform: uppercase; }
        a { text-decoration: none; color: inherit; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: #000; }
        ::-webkit-scrollbar-thumb { background: #222; border-radius: 10px; }
    </style>
</head>
<body>
    <header>
        <h1>Alice</h1>
        <p>Curated Archive / Pure-Flow Architecture</p>
    </header>
    <div class="container">
EOF

find . -maxdepth 2 -not -path '*/.*' -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort | while read -r img; do
    clean_path="${img#./}"
    folder=$(dirname "$clean_path")
    filename=$(basename "$clean_path")
    
    if [ "$folder" != "." ]; then
        echo "        <div class='card'>" >> index.html
        echo "            <a href='$clean_path' target='_blank'>" >> index.html
        echo "                <img src='$clean_path' loading='lazy'>" >> index.html
        echo "                <div class='info'>" >> index.html
        echo "                    <span>$folder / $filename</span>" >> index.html
        echo "                    <span>OPEN</span>" >> index.html
        echo "                </div>" >> index.html
        echo "            </a>" >> index.html
        echo "        </div>" >> index.html
    fi
done

cat <<EOF >> index.html
    </div>
</body>
</html>
EOF

chmod +x build.sh

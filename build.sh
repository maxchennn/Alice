#!/bin/bash

cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alice Era // Archive</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Syne:wght@300;400;700&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --bg: #080808;
            --fg: #efefef;
            --dim: #1e1e1e;
            --muted: #555;
        }

        body {
            background: var(--bg);
            color: var(--fg);
            font-family: 'Syne', sans-serif;
            font-weight: 300;
            overflow-x: hidden;
            cursor: none;
        }

        .cursor { position: fixed; width: 8px; height: 8px; background: var(--fg); border-radius: 50%; pointer-events: none; z-index: 9999; transform: translate(-50%, -50%); }
        .cursor-ring { position: fixed; width: 32px; height: 32px; border: 1px solid rgba(255,255,255,0.3); border-radius: 50%; pointer-events: none; z-index: 9998; transform: translate(-50%, -50%); transition: width 0.3s, height 0.3s; }

        header {
            height: 60vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 0 6vw;
            border-bottom: 1px solid var(--dim);
        }

        .header-label {
            font-size: 0.65rem;
            letter-spacing: 0.35em;
            color: var(--muted);
            text-transform: uppercase;
            margin-bottom: 1rem;
        }

        h1 {
            font-family: 'Playfair Display', serif;
            font-weight: 400;
            font-size: clamp(4rem, 12vw, 10rem);
            line-height: 0.88;
            letter-spacing: -0.04em;
        }

        h1 em { font-style: italic; color: var(--muted); display: block; }

        .category-section {
            padding: 6vh 0;
            border-bottom: 1px solid #111;
        }

        .section-label {
            font-size: 0.7rem;
            letter-spacing: 0.4em;
            color: var(--muted);
            text-transform: uppercase;
            margin-bottom: 2rem;
            padding-left: 6vw;
            display: flex;
            align-items: center;
            gap: 2rem;
        }

        .section-label::after { content: ''; flex: 1; height: 1px; background: var(--dim); }

        .carousel-container {
            display: flex;
            overflow-x: auto;
            overflow-y: hidden;
            padding: 0 6vw 20px;
            gap: 20px;
            scroll-snap-type: x mandatory;
            scrollbar-width: none;
        }

        .carousel-container::-webkit-scrollbar { display: none; }

        .card {
            flex: 0 0 450px;
            scroll-snap-align: start;
            position: relative;
            overflow: hidden;
            background: var(--dim);
            aspect-ratio: 16/10;
        }

        @media (max-width: 768px) { .card { flex: 0 0 300px; } }

        .card img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            filter: brightness(0.8) grayscale(100%);
            transition: transform 0.9s cubic-bezier(0.25,0.46,0.45,0.94), filter 0.6s ease;
        }

        .card:hover img {
            transform: scale(1.05);
            filter: brightness(1) grayscale(0%);
        }

        .card-overlay {
            position: absolute;
            inset: 0;
            background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, transparent 100%);
            opacity: 0;
            transition: opacity 0.4s ease;
            display: flex;
            align-items: flex-end;
            padding: 20px;
        }

        .card:hover .card-overlay { opacity: 1; }
        .card-info { font-size: 0.6rem; letter-spacing: 0.2em; color: var(--fg); text-transform: uppercase; }

        footer {
            padding: 8vh 6vw;
            text-align: center;
            font-size: 0.6rem;
            letter-spacing: 0.3em;
            color: var(--muted);
            text-transform: uppercase;
        }
    </style>
</head>
<body>

<div class="cursor" id="cursor"></div>
<div class="cursor-ring" id="ring"></div>

<header>
    <p class="header-label">Digital Archive</p>
    <h1>Alice<em>Era</em></h1>
</header>

<main>
EOF

find . -maxdepth 1 -type d -not -path '*/.*' -not -path '.' | sort | while read -r dir; do
    folder_name="${dir#./}"
    has_images=$(find "$dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | wc -l)
    
    if [ "$has_images" -gt 0 ]; then
        echo "    <section class='category-section'>" >> index.html
        echo "        <div class='section-label'>$folder_name</div>" >> index.html
        echo "        <div class='carousel-container'>" >> index.html
        
        find "$dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort | while read -r img; do
            clean_path="${img#./}"
            filename=$(basename "$clean_path")
            echo "            <div class='card'>" >> index.html
            echo "                <a href='$clean_path' target='_blank'>" >> index.html
                echo "                    <img src='$clean_path' loading='lazy'>" >> index.html
                echo "                    <div class='card-overlay'><span class='card-info'>$filename</span></div>" >> index.html
            echo "                </a>" >> index.html
            echo "            </div>" >> index.html
        done
        
        echo "        </div>" >> index.html
        echo "    </section>" >> index.html
    fi
done

cat <<EOF >> index.html
</main>

<footer>
    Alice Era // 2026 Archive
</footer>

<script>
    const cur = document.getElementById('cursor');
    const ring = document.getElementById('ring');
    let mx = 0, my = 0, rx = 0, ry = 0;

    document.addEventListener('mousemove', e => {
        mx = e.clientX; my = e.clientY;
        cur.style.left = mx + 'px'; cur.style.top = my + 'px';
    });

    (function anim() {
        rx += (mx - rx) * 0.12; ry += (my - ry) * 0.12;
        ring.style.left = rx + 'px'; ring.style.top = ry + 'px';
        requestAnimationFrame(anim);
    })();
</script>

</body>
</html>
EOF

chmod +x build.sh

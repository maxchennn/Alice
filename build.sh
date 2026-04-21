#!/bin/bash

cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alice // Archive</title>
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;500&family=Fraunces:ital,wght@1,300&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root { --bg: #050505; --fg: #e0dcd3; --dim: #121212; --muted: #444; }

        body {
            background: var(--bg); color: var(--fg);
            font-family: 'Space Grotesk', sans-serif; font-weight: 300;
            overflow-x: hidden; cursor: none;
        }

        /* Custom Cursor */
        .cursor { position: fixed; width: 6px; height: 6px; background: var(--fg); border-radius: 50%; pointer-events: none; z-index: 9999; transform: translate(-50%, -50%); }
        .cursor-ring { position: fixed; width: 26px; height: 26px; border: 1px solid rgba(224,220,211,0.15); border-radius: 50%; pointer-events: none; z-index: 9998; transform: translate(-50%, -50%); transition: width 0.3s, height 0.3s; }

        header {
            height: 70vh; display: flex; flex-direction: column; justify-content: center;
            padding: 0 8vw; position: relative; border-bottom: 1px solid var(--dim);
        }

        h1 { font-family: 'Fraunces', serif; font-style: italic; font-weight: 300; font-size: clamp(4rem, 12vw, 10rem); line-height: 0.9; letter-spacing: -0.03em; }
        .header-meta { margin-top: 2rem; font-size: 0.65rem; letter-spacing: 0.4em; text-transform: uppercase; color: var(--muted); }

        .gallery-section { padding: 8vw; }
        .gallery { columns: 3; column-gap: 20px; }
        @media (max-width: 1100px) { .gallery { columns: 2; } }
        @media (max-width: 700px) { .gallery { columns: 1; } }

        .card {
            break-inside: avoid; margin-bottom: 20px; position: relative;
            background: var(--dim); overflow: hidden; opacity: 0; transform: translateY(30px);
            transition: all 0.8s cubic-bezier(0.2, 1, 0.3, 1);
        }
        .card.visible { opacity: 1; transform: translateY(0); }
        .card img { width: 100%; display: block; filter: grayscale(100%); transition: transform 1.2s cubic-bezier(0.2, 1, 0.3, 1), filter 0.8s ease; }
        .card:hover img { transform: scale(1.08); filter: grayscale(0%); }
        .card-overlay { position: absolute; inset: 0; background: linear-gradient(transparent, rgba(0,0,0,0.8)); opacity: 0; transition: opacity 0.4s ease; display: flex; align-items: flex-end; padding: 20px; }
        .card:hover .card-overlay { opacity: 1; }
        .card-num { font-size: 0.6rem; letter-spacing: 0.2em; color: var(--fg); text-transform: uppercase; }
    </style>
</head>
<body>
    <div class="cursor" id="cursor"></div>
    <div class="cursor-ring" id="ring"></div>
    <header>
        <h1>Alice Archive</h1>
        <p class="header-meta">Pure-Flow Architecture // Collection v1</p>
    </header>
    <div class="gallery-section"><div id="gallery" class="gallery">
EOF

# Dinamik Tarama
find . -maxdepth 2 -not -path '*/.*' -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort | while read -r img; do
    clean_path="${img#./}"
    folder=$(dirname "$clean_path")
    filename=$(basename "$clean_path")
    if [ "$folder" != "." ]; then
        echo "        <div class='card'><a href='$clean_path' target='_blank'><img src='$clean_path' loading='lazy'><div class='card-overlay'><span class='card-num'>$folder / $filename</span></div></a></div>" >> index.html
    fi
done

cat <<EOF >> index.html
    </div></div>
    <script>
        const cur = document.getElementById('cursor'); const ring = document.getElementById('ring');
        let mx = 0, my = 0, rx = 0, ry = 0;
        document.addEventListener('mousemove', e => { mx = e.clientX; my = e.clientY; cur.style.left = mx + 'px'; cur.style.top = my + 'px'; });
        (function animateRing() { rx += (mx - rx) * 0.15; ry += (my - ry) * 0.15; ring.style.left = rx + 'px'; ring.style.top = ry + 'px'; requestAnimationFrame(animateRing); })();
        const obs = new IntersectionObserver(entries => { entries.forEach((e, i) => { if (e.isIntersecting) { setTimeout(() => e.target.classList.add('visible'), i * 50); obs.unobserve(e.target); } }); }, { threshold: 0.1 });
        document.querySelectorAll('.card').forEach(c => obs.observe(c));
    </script>
</body>
</html>
EOF

chmod +x build.sh

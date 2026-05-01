#!/usr/bin/env bash

# MIT License
# Copyright (c) 2025
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

generate_thumbnails() {
  echo "generate thumbnails ..."
  mkdir -p thumbnails
  rm -rf thumbnails/*
  
  total_images=$(find . -mindepth 2 -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | grep -v './thumbnails/' | wc -l)
  current_image=0
  
  for section_dir in ./*/; do
    # Skip non-category dirs
    case "${section_dir}" in
      ./thumbnails/|./.git/) continue ;;
    esac
    [ -d "$section_dir" ] || continue
    section_name="${section_dir%/}"
    section_name="${section_name##*/}"
    mkdir -p "thumbnails/$section_name"
    
    for img in "${section_dir%/}"/*; do
      [ -f "$img" ] || continue
      case "$img" in
        *.jpg|*.jpeg|*.png|*.JPG|*.JPEG|*.PNG) ;;
        *) continue ;;
      esac
      
      current_image=$((current_image + 1))
      local img_filename="${img##*/}"
      local thumbnail="thumbnails/$section_name/$img_filename"
      echo "($current_image/$total_images): $img -> $thumbnail"
      magick "$img" -resize 300x300 "$thumbnail"
    done
    
    if [ -d "${section_dir%/}/light" ]; then
      mkdir -p "thumbnails/$section_name/light"
      for img in "${section_dir%/}/light"/*; do
        [ -f "$img" ] || continue
        case "$img" in
          *.jpg|*.jpeg|*.png|*.JPG|*.JPEG|*.PNG) ;;
          *) continue ;;
        esac
        
        current_image=$((current_image + 1))
        local img_filename="${img##*/}"
        local thumbnail="thumbnails/$section_name/light/$img_filename"
        echo "($current_image/$total_images): $img -> $thumbnail"
        magick "$img" -resize 300x300 "$thumbnail"
      done
    fi
  done
  
  echo "Thumbnail generation complete: $total_images images processed"
}

check_has_light_folder() {
  local section_dir=$1
  [ -d "$section_dir/light" ] && echo "true" || echo "false"
}

count_images_in_dir() {
  local dir=$1
  find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l
}

create_section_data() {
  local section=$1
  local subdir=$2
  local maxPerPage=8
  local has_light=$(check_has_light_folder "$subdir")
  
  echo "Creating data for section: $section"
  
  local data_file="${section}_data.js"
  
  cat > "$data_file" << EOF
// Data for $section section
window.sectionData = window.sectionData || {};
window.sectionData['$section'] = {
  hasLight: $has_light,
  maxPerPage: $maxPerPage,
  dark: [
EOF

  for wallpaper in "$subdir"/*; do
    [ -f "$wallpaper" ] || continue
    case "$wallpaper" in
      *.jpg|*.jpeg|*.png|*.JPG|*.JPEG|*.PNG) ;;
      *) continue ;;
    esac
    
    local img_path="${wallpaper#./}"
    local img_filename="${wallpaper##*/}"
    local thumbnail_path="thumbnails/$section/$img_filename"
    echo "    { src: '$img_path', thumb: '$thumbnail_path', alt: '$img_filename' }," >> "$data_file"
  done

  echo "  ]," >> "$data_file"
  if [ "$has_light" = "true" ]; then
    echo "  light: [" >> "$data_file"
    for wallpaper in "$subdir/light"/*; do
      [ -f "$wallpaper" ] || continue
      case "$wallpaper" in
        *.jpg|*.jpeg|*.png|*.JPG|*.JPEG|*.PNG) ;;
        *) continue ;;
      esac
      
      local img_path="${wallpaper#./}"
      local img_filename="${wallpaper##*/}"
      local thumbnail_path="thumbnails/$section/light/$img_filename"
      echo "    { src: '$img_path', thumb: '$thumbnail_path', alt: '$img_filename' }," >> "$data_file"
    done
    echo "  ]" >> "$data_file"
  else
    echo "  light: []" >> "$data_file"
  fi

  echo "};" >> "$data_file"
}

# Clean up old files
rm -f *.html *.js

# Generate thumbnails
generate_thumbnails

# Create main index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <title>Alice</title>
  <style>
    /* ── PALETTE ── */
    :root {
      --c0: #0d0d0d;
      --c1: #111318;
      --c2: #1a1d26;
      --c3: #22263a;
      --c4: #2e3450;
      --fg:  #cdd6f4;
      --fg2: #89b4fa;
      --fg3: #74c7ec;
      --ac1: #89dceb;
      --ac2: #94e2d5;
      --ac3: #a6e3a1;
      --ac4: #f9e2af;
      --ac5: #fab387;
      --ac6: #eba0ac;
      --ac7: #cba6f7;

      --bg:     var(--c0);
      --bg2:    var(--c1);
      --bg3:    var(--c2);
      --border: var(--c3);
      --text:   var(--fg);
      --muted:  #6c7086;
      --radius: 6px;
    }

    [data-theme="light"] {
      /* Catppuccin Latte — eski tarayıcı uyumlu, blur yok */
      --bg:    #eff1f5;   /* base       */
      --bg2:   #ffffff;   /* kartlar tam beyaz — net kontrast */
      --bg3:   #e6e9ef;   /* surface0   */
      --border:#8c8fa1;   /* overlay1 — ince ama belirgin */
      --text:  #4c4f69;   /* text       */
      --muted: #9ca0b0;   /* subtext0   */

      --fg2:   #1e66f5;   /* blue       */
      --fg3:   #04a5e5;   /* sapphire   */
      --ac1:   #179299;   /* teal       */
      --ac2:   #209fb5;   /* sky        */
      --ac3:   #40a02b;   /* green      */
      --ac4:   #df8e1d;   /* yellow     */
      --ac5:   #fe640b;   /* peach      */
      --ac6:   #e64553;   /* red        */
      --ac7:   #8839ef;   /* mauve      */
    }

    /* ── Light mode overrides — no blur, no rgba opacity tricks ── */
    [data-theme="light"] h1 {
      background: linear-gradient(135deg, #179299 0%, #8839ef 50%, #e64553 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    /* Kategori etiketleri — opak arka plan, no color-mix */
    [data-theme="light"] .sh1 { color: #179299; background: #d8f4f5; border-color: #b3e8ea; }
    [data-theme="light"] .sh2 { color: #179299; background: #d1f2f7; border-color: #a8e4ee; }
    [data-theme="light"] .sh3 { color: #40a02b; background: #daf0d4; border-color: #b5e0ac; }
    [data-theme="light"] .sh4 { color: #b06a00; background: #faecd1; border-color: #f0d5a0; }
    [data-theme="light"] .sh5 { color: #c94800; background: #fde8d8; border-color: #f8c9a8; }
    [data-theme="light"] .sh6 { color: #c2003a; background: #fcdde1; border-color: #f5b5be; }
    [data-theme="light"] .sh7 { color: #8839ef; background: #ead8fb; border-color: #d0aaf5; }

    /* Kartlar — beyaz + ince gölge, blur yok */
    [data-theme="light"] .section {
      background: #ffffff;
      box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    }
    [data-theme="light"] .section.selected {
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    [data-theme="light"] .c a {
      background: #ffffff;
      box-shadow: 0 1px 3px rgba(0,0,0,0.07);
    }
    [data-theme="light"] .c a:hover {
      border-color: #1e66f5;
      box-shadow: 0 2px 8px rgba(0,0,0,0.12);
      transform: translateY(-3px);
    }

    [data-theme="light"] .theme-btn.active {
      background: #1e66f5;
      border-color: #1e66f5;
      color: #ffffff;
    }
    [data-theme="light"] .theme-btn:hover {
      color: #4c4f69;
      border-color: #4c4f69;
    }

    [data-theme="light"] .pager-btn.selected {
      background: #1e66f5;
      border-color: #1e66f5;
      color: #ffffff;
    }
    [data-theme="light"] .pager-btn:hover {
      color: #4c4f69;
      border-color: #4c4f69;
    }

    [data-theme="light"] .float-btn {
      background: #ffffff;
      border-color: #acb0be;
      box-shadow: 0 1px 4px rgba(0,0,0,0.08);
    }
    [data-theme="light"] .float-btn:hover {
      background: #ffffff;
      border-color: #1e66f5;
      color: #1e66f5;
      box-shadow: 0 2px 8px rgba(0,0,0,0.12);
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'SF Mono', 'Fira Code', 'JetBrains Mono', monospace;
      font-size: 14px;
      min-height: 100vh;
      transition: background 0.3s, color 0.3s;
    }

    /* ── NOISE OVERLAY ── */
    body::before {
      content: '';
      position: fixed;
      inset: 0;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
      pointer-events: none;
      z-index: 0;
    }

    /* ── LAYOUT ── */
    main {
      position: relative;
      z-index: 1;
      max-width: 1100px;
      margin: 0 auto;
      padding: 60px 24px 100px;
    }

    /* ── HEADER ── */
    h1 {
      font-size: clamp(2rem, 5vw, 3.5rem);
      font-weight: 800;
      letter-spacing: -0.03em;
      margin-bottom: 56px;
      background: linear-gradient(135deg, var(--ac1) 0%, var(--ac7) 50%, var(--ac6) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    /* ── SECTION HEADINGS ── */
    .section-heading {
      display: inline-block;
      font-size: 0.7rem;
      font-weight: 700;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      padding: 6px 14px;
      border-radius: var(--radius);
      margin-bottom: 0;
      cursor: pointer;
      border: 1.5px solid transparent;
      transition: border-color 0.2s, background 0.2s, transform 0.15s;
      user-select: none;
    }
    .section-heading:hover  { border-color: currentColor; transform: translateY(-1px); }
    .section-heading:active { transform: translateY(0); }

    /* 7 accent colors cycling */
    .sh1 { color: #89dceb; background: #152229; border-color: #1e3a44; }
    .sh2 { color: #94e2d5; background: #14231f; border-color: #1d3830; }
    .sh3 { color: #a6e3a1; background: #182318; border-color: #253d24; }
    .sh4 { color: #f9e2af; background: #2a2214; border-color: #3d301a; }
    .sh5 { color: #fab387; background: #271c12; border-color: #3d2a18; }
    .sh6 { color: #eba0ac; background: #271418; border-color: #3d1f25; }
    .sh7 { color: #cba6f7; background: #1e1530; border-color: #2e2048; }

    /* ── SECTION WRAPPER ── */
    .section {
      margin-bottom: 12px;
      border-radius: 10px;
      overflow: hidden;
      border: 1px solid transparent;
      transition: border-color 0.3s;
    }
    .section.selected {
      border-color: var(--border);
    }

    .section-header {
      padding: 14px 20px;
      display: flex;
      align-items: center;
      gap: 12px;
    }

    /* ── SECTION CONTENT ── */
    .section-content {
      padding: 0 20px;
      max-height: 0;
      overflow: hidden;
      opacity: 0;
      transition: max-height 0.4s cubic-bezier(0.4,0,0.2,1),
                  opacity 0.3s ease,
                  padding 0.3s ease;
    }
    .section.selected .section-content {
      max-height: 4000px;
      opacity: 1;
      padding: 0 20px 24px;
    }

    /* ── THEME SWITCHER ── */
    .section-theme-switcher {
      display: flex;
      gap: 6px;
      margin-bottom: 18px;
      opacity: 0;
      transform: translateY(-6px);
      transition: opacity 0.3s 0.1s, transform 0.3s 0.1s;
    }
    .section.selected .section-theme-switcher {
      opacity: 1;
      transform: translateY(0);
    }

    .theme-btn {
      padding: 5px 14px;
      font-family: inherit;
      font-size: 0.72rem;
      font-weight: 600;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      border: 1.5px solid var(--border);
      border-radius: var(--radius);
      background: transparent;
      color: var(--muted);
      cursor: pointer;
      transition: all 0.2s;
    }
    .theme-btn:hover  { color: var(--text); border-color: var(--text); }
    .theme-btn.active {
      background: var(--fg2);
      border-color: var(--fg2);
      color: var(--c0);
    }

    /* ── IMAGE GRID ── */
    .c {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 10px;
    }
    .c a {
      display: block;
      border-radius: var(--radius);
      overflow: hidden;
      border: 1px solid var(--border);
      transition: border-color 0.2s, transform 0.2s, box-shadow 0.2s;
    }
    .c a:hover {
      border-color: var(--fg2);
      transform: translateY(-3px);
      box-shadow: 0 8px 24px rgba(0,0,0,0.4);
    }
    .c img {
      width: 100%;
      height: 140px;
      object-fit: cover;
      display: block;
      transition: filter 0.2s;
    }
    .c a:hover img { filter: brightness(1.08); }

    /* ── PAGER ── */
    .pager {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-bottom: 16px;
    }
    .pager-btn {
      padding: 4px 12px;
      font-family: inherit;
      font-size: 0.75rem;
      font-weight: 600;
      border: 1.5px solid var(--border);
      border-radius: var(--radius);
      background: transparent;
      color: var(--muted);
      cursor: pointer;
      transition: all 0.2s;
    }
    .pager-btn:hover    { color: var(--text); border-color: var(--text); }
    .pager-btn.selected {
      background: var(--fg2);
      border-color: var(--fg2);
      color: var(--c0);
    }

    /* ── SUBSECTION TOGGLE ── */
    .subsection-content         { display: none; }
    .subsection-content.active  { display: block; }

    /* ── LOADING ── */
    .loading {
      padding: 32px;
      text-align: center;
      color: var(--muted);
      font-size: 0.8rem;
      letter-spacing: 0.1em;
    }

    /* ── FLOAT BUTTONS ── */
    .float-btns {
      position: fixed;
      bottom: 28px;
      right: 28px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      z-index: 100;
    }
    .float-btn {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: var(--bg2);
      border: 1.5px solid var(--border);
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.2s;
    }
    .float-btn:hover {
      background: var(--bg3);
      border-color: var(--fg2);
      color: var(--fg2);
      transform: translateY(-2px);
      box-shadow: 0 4px 16px rgba(0,0,0,0.3);
    }
    .float-btn svg { width: 18px; height: 18px; }

    /* ── CHEVRON ── */
    .chevron {
      width: 14px;
      height: 14px;
      color: var(--muted);
      transition: transform 0.3s;
      flex-shrink: 0;
    }
    .section.selected .chevron { transform: rotate(90deg); }

    /* ── HIDDEN ── */
    .hidden { display: none !important; }

    /* ── SCROLLBAR ── */
    ::-webkit-scrollbar       { width: 6px; }
    ::-webkit-scrollbar-track { background: var(--bg); }
    ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
    ::-webkit-scrollbar-thumb:hover { background: var(--muted); }
  </style>
</head>
<body>
  <div class='float-btns'>
    <a href='https://github.com' target='_blank' class='float-btn' title='Source code'>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4"/><path d="M9 18c-4.51 2-5-2-7-2"/></svg>
    </a>
    <button onclick='switchMainTheme()' class='float-btn' title='Switch theme'>
      <svg id="light-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>
      <svg id="dark-icon" class="hidden" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"/></svg>
    </button>
  </div>

  <main>
    <h1>Alice</h1>
EOF

# Generate sections
color=1
declare -a sections
declare -a sections_with_light

for subdir in ./*/; do
  # Skip non-category dirs
  case "${subdir}" in
    ./thumbnails/|./.git/) continue ;;
  esac
  [ -d "$subdir" ] || continue
  section="${subdir%/}"
  section="${section##*/}"
  sections+=("$section")
  has_light=$(check_has_light_folder "$subdir")
  
  if [ "$has_light" = "true" ]; then
    sections_with_light+=("$section")
  fi
  
  create_section_data "$section" "$subdir"
  
  echo "    <div class='section' id='$section'>" >> index.html
  echo "      <div class='section-header' onclick='activeSection(\"$section\")' style='cursor:pointer'>" >> index.html
  echo "        <svg class='chevron' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><path d='m9 18 6-6-6-6'/></svg>" >> index.html
  echo "        <span class='section-heading sh$color'>$(echo "$section" | tr a-z A-Z)</span>" >> index.html
  echo "      </div>" >> index.html
  
  echo "      <div class='section-content' id='$section-content'>" >> index.html
  
  if [ "$has_light" = "true" ]; then
    echo "        <div class='section-theme-switcher'>" >> index.html
    echo "          <button class='theme-btn active' onclick='switchSectionTheme(\"$section\", \"dark\")' id='$section-dark-btn'>Dark</button>" >> index.html
    echo "          <button class='theme-btn' onclick='switchSectionTheme(\"$section\", \"light\")' id='$section-light-btn'>Light</button>" >> index.html
    echo "        </div>" >> index.html
  fi
  
  echo "        <div class='loading'>loading...</div>" >> index.html
  echo "      </div>" >> index.html
  echo "    </div>" >> index.html

  color=$((color + 1))
  if [ "$color" -eq 8 ]; then
    color=1
  fi
done

for section in "${sections[@]}"; do
  echo "  <script src='${section}_data.js'></script>" >> index.html
done

cat >> index.html << 'EOF'
  <script>
    let activeSectionName = null;
    let sectionStates = {};

    function initSectionState(section) {
      if (!sectionStates[section]) {
        sectionStates[section] = {
          currentTheme: 'dark',
          currentPages: { dark: 1, light: 1 },
          loaded: false
        };
      }
    }

    function activeSection(section) {
      const targetSection = document.getElementById(section);
      const isAlreadyOpen = targetSection.classList.contains('selected');

      // Close all
      document.querySelectorAll('.section').forEach(s => s.classList.remove('selected'));
      activeSectionName = null;

      // If it wasn't open, open it
      if (!isAlreadyOpen) {
        targetSection.classList.add('selected');
        activeSectionName = section;
        initSectionState(section);

        if (!sectionStates[section].loaded) {
          loadSectionContent(section);
        }
        if (window.sectionData[section].hasLight) {
          switchSectionTheme(section, 'dark');
        }
        setTimeout(() => {
          targetSection.scrollIntoView({ block: 'start', behavior: 'smooth' });
        }, 100);
      }
    }

    function loadSectionContent(section) {
      const contentDiv = document.getElementById(section + '-content');
      const data = window.sectionData[section];
      if (!data) {
        contentDiv.innerHTML = '<div class="loading">error: data not found</div>';
        return;
      }

      // Rebuild innerHTML, keep theme-switcher if present
      let themeSwitcher = '';
      const existingSwitcher = contentDiv.querySelector('.section-theme-switcher');
      if (existingSwitcher) themeSwitcher = existingSwitcher.outerHTML;

      let html = themeSwitcher;

      if (data.dark.length > 0) {
        html += `<div class="subsection-content active" id="${section}-dark">`;
        const darkPages = Math.ceil(data.dark.length / data.maxPerPage);
        if (darkPages > 1) {
          html += '<div class="pager">';
          for (let i = 1; i <= darkPages; i++) {
            html += `<button class="pager-btn${i===1?' selected':''}" onclick="loadPage('${section}','dark',${i})">${i}</button>`;
          }
          html += '</div>';
        }
        html += `<div id="${section}-dark-content">${generateImageGrid(data.dark.slice(0, data.maxPerPage))}</div>`;
        html += '</div>';
      }

      if (data.hasLight && data.light.length > 0) {
        html += `<div class="subsection-content" id="${section}-light">`;
        const lightPages = Math.ceil(data.light.length / data.maxPerPage);
        if (lightPages > 1) {
          html += '<div class="pager">';
          for (let i = 1; i <= lightPages; i++) {
            html += `<button class="pager-btn${i===1?' selected':''}" onclick="loadPage('${section}','light',${i})">${i}</button>`;
          }
          html += '</div>';
        }
        html += `<div id="${section}-light-content">${generateImageGrid(data.light.slice(0, data.maxPerPage))}</div>`;
        html += '</div>';
      }

      contentDiv.innerHTML = html;
      sectionStates[section].loaded = true;
    }

    function generateImageGrid(images) {
      let html = '<div class="c">';
      images.forEach(img => {
        html += `<a target="_blank" href="${img.src}">
          <img loading="lazy" src="${img.thumb}" alt="${img.alt}">
        </a>`;
      });
      html += '</div>';
      return html;
    }

    function switchSectionTheme(section, theme) {
      initSectionState(section);
      sectionStates[section].currentTheme = theme;

      const darkBtn  = document.getElementById(section + '-dark-btn');
      const lightBtn = document.getElementById(section + '-light-btn');
      if (darkBtn && lightBtn) {
        darkBtn.classList.toggle('active', theme === 'dark');
        lightBtn.classList.toggle('active', theme === 'light');
      }

      const darkContent  = document.getElementById(section + '-dark');
      const lightContent = document.getElementById(section + '-light');
      if (darkContent && lightContent) {
        darkContent.classList.toggle('active', theme === 'dark');
        lightContent.classList.toggle('active', theme === 'light');
      }

      loadPage(section, theme, 1);
    }

    function loadPage(section, theme, page) {
      const data = window.sectionData[section];
      const images = data[theme];
      const startIdx = (page - 1) * data.maxPerPage;
      const pageImages = images.slice(startIdx, startIdx + data.maxPerPage);

      const contentDiv = document.getElementById(`${section}-${theme}-content`);
      if (contentDiv) contentDiv.innerHTML = generateImageGrid(pageImages);

      const pagerBtns = document.getElementById(`${section}-${theme}`)?.getElementsByClassName('pager-btn');
      if (pagerBtns) {
        for (let i = 0; i < pagerBtns.length; i++) {
          pagerBtns[i].classList.toggle('selected', i === page - 1);
        }
      }

      initSectionState(section);
      sectionStates[section].currentPages[theme] = page;
    }

    // ── Main theme ──
    function setMainTheme(theme) {
      document.documentElement.dataset.theme = theme === 'light' ? 'light' : '';
      document.body.dataset.theme = theme;
      document.getElementById('light-icon')?.classList.toggle('hidden', theme === 'light');
      document.getElementById('dark-icon')?.classList.toggle('hidden', theme === 'dark');
    }

    function switchMainTheme() {
      const current = document.body.dataset.theme;
      setMainTheme(current === 'light' ? 'dark' : 'light');
    }

    document.addEventListener('DOMContentLoaded', () => {
EOF

echo "      activeSection('${sections[0]}');" >> index.html

cat >> index.html << 'EOF'
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      setMainTheme(prefersDark ? 'dark' : 'light');
    });
  </script>
</body>
</html>
EOF

echo "Build complete! Generated ${#sections[@]} sections."
echo "Sections with light variants: ${sections_with_light[*]}"

#!/bin/bash
# ============================================================
#  PUBLISH WEBSITE  —  double-click to put your photos live.
#
#  ONE photo folder (nothing else to think about):
#    ~/Documents/GitHub/chillchoi.github.io/photos/<place>/
#    place = capecod, chicago, japan, hawaii, california, seoul
#
#  ADD photos:  drag ANY photos into a place folder — any name,
#               any format (iPhone .HEIC, big camera .JPG, .png).
#               This script auto-resizes, renames, and de-dupes them.
#  DELETE photos: just drag them to the Trash. The same photo is
#               also removed from the wallpapers folder, and the
#               rest are renumbered so there are no gaps.
#  Then: double-click this file. Done.
# ============================================================

CH="$HOME/Documents/GitHub/chillchoi.github.io"
PLACES="capecod chicago japan hawaii california seoul"

cd "$CH" 2>/dev/null || { echo "Could not find chillchoi.github.io in ~/Documents/GitHub."; read -n 1 -s -r -p "Press any key to close."; exit 1; }

echo "== Preparing photos =="
for p in $PLACES; do
  d="$CH/photos/$p"
  [ -d "$d" ] || continue

  # photos deleted from this place: delete the exact same photo from the wallpapers folder too
  WP=$(ls -d "$CH"/photos/wallpapers* 2>/dev/null | head -1)
  git ls-files -d -- "photos/$p" | while read -r gone; do
    h=$(git show HEAD:"$gone" | shasum | awk '{print $1}')
    [ -n "$WP" ] && for w in "$WP"/*; do
      [ -f "$w" ] && [ "$(shasum "$w" | awk '{print $1}')" = "$h" ] && rm -f "$w" && echo "  wallpapers: removed $(basename "$w") (same as deleted $(basename "$gone"))"
    done
  done

  # close gaps left by deleted photos (1,2,4 -> 1,2,3); two passes so names never collide
  k=0
  for n in $(ls "$d" | sed -n "s/^${p}_\([0-9]*\)\.jpg$/\1/p" | sort -n); do k=$((k + 1)); mv "$d/${p}_$n.jpg" "$d/tmp_$k.jpg"; done
  for f in "$d"/tmp_*.jpg; do [ -e "$f" ] && mv "$f" "$d/${p}_${f##*tmp_}"; done

  # highest existing place_N.jpg
  max=0
  for f in "$d"/"${p}"_*.jpg; do
    [ -e "$f" ] || continue
    n=$(basename "$f" .jpg); n=${n#"${p}_"}; case "$n" in *[!0-9]*|"") continue ;; esac
    [ "$n" -gt "$max" ] && max=$n
  done

  # bring in any non-conforming images (camera dumps, HEIC, PNG, etc.)
  for f in "$d"/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    echo "$b" | grep -Eq "^${p}_[0-9]+\.jpg$" && continue
    ext=$(echo "${b##*.}" | tr 'A-Z' 'a-z')
    case "$ext" in
      jpg|jpeg|png|heic|heif|tif|tiff) ;;
      *) continue ;;
    esac
    max=$((max + 1))
    out="$d/${p}_$max.jpg"
    if sips -Z 1400 -s format jpeg "$f" --out "$out" >/dev/null 2>&1; then
      rm -f "$f"
      echo "  $p: added $(basename "$out")  (from $b)"
    else
      echo "  $p: could not convert $b — left it alone"
      max=$((max - 1))
    fi
  done

  # remove exact-duplicate photos (same image dropped twice); keep the lower number
  tmp=$(mktemp)
  for f in "$d"/"${p}"_*.jpg; do
    [ -e "$f" ] || continue
    echo "$(shasum "$f" | awk '{print $1}')|$f"
  done | sort > "$tmp"
  awk -F'|' '{ if ($1==prev) print $2; else prev=$1 }' "$tmp" | while read -r dup; do
    [ -n "$dup" ] && rm -f "$dup" && echo "  $p: removed duplicate $(basename "$dup")"
  done
  rm -f "$tmp"
done

# write the tiny count file the site reads (highest photo number per place)
{
  printf 'window.PHOTO_COUNTS={'
  i=0
  for p in $PLACES; do
    d="$CH/photos/$p"; mx=0
    for f in "$d"/"${p}"_*.jpg; do
      [ -e "$f" ] || continue
      n=$(basename "$f" .jpg); n=${n#"${p}_"}; case "$n" in *[!0-9]*|"") continue ;; esac
      [ "$n" -gt "$mx" ] && mx=$n
    done
    [ "$i" -ne 0 ] && printf ','
    printf '"%s":%d' "$p" "$mx"; i=1
  done
  printf '};\n'
} > "$CH/photos/counts.js"

# strip macOS junk so it never gets committed
find "$CH/photos" -name '.DS_Store' -delete 2>/dev/null

echo "Publishing the live site..."
git add -A
git commit -m "update site $(date '+%Y-%m-%d %H:%M')" || echo "(nothing changed since last time)"
git push || echo ">> PUSH FAILED — open GitHub Desktop, select chillchoi.github.io, and click Push."

echo ""
echo "Done. Refresh https://chillchoi.github.io in ~1 minute (Cmd+Shift+R to skip the cache)."
read -n 1 -s -r -p "Press any key to close."

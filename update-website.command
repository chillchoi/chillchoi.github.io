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
#  DELETE photos: just drag them to the Trash.
#  Then: double-click this file. Done.
# ============================================================

CH="$HOME/Documents/GitHub/chillchoi.github.io"
PLACES="capecod chicago japan hawaii california seoul"

cd "$CH" 2>/dev/null || { echo "Could not find chillchoi.github.io in ~/Documents/GitHub."; read -n 1 -s -r -p "Press any key to close."; exit 1; }

echo "== Preparing photos =="
for p in $PLACES; do
  d="$CH/photos/$p"
  [ -d "$d" ] || continue

  # highest existing NN.jpg
  max=0
  for f in "$d"/[0-9][0-9].jpg; do
    [ -e "$f" ] || continue
    n=$(basename "$f" .jpg); n=$((10#$n))
    [ "$n" -gt "$max" ] && max=$n
  done

  # bring in any non-conforming images (camera dumps, HEIC, PNG, etc.)
  for f in "$d"/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    echo "$b" | grep -Eq '^[0-9][0-9]\.jpg$' && continue
    ext=$(echo "${b##*.}" | tr 'A-Z' 'a-z')
    case "$ext" in
      jpg|jpeg|png|heic|heif|tif|tiff) ;;
      *) continue ;;
    esac
    max=$((max + 1))
    out=$(printf "%s/%02d.jpg" "$d" "$max")
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
  for f in "$d"/[0-9][0-9].jpg; do
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
    for f in "$d"/[0-9][0-9].jpg; do
      [ -e "$f" ] || continue
      n=$(basename "$f" .jpg); n=$((10#$n))
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

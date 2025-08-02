#!/bin/bash
# wouldnt expect this to appear but it does so yea
END_PAGE="doesn’t have any public repositories yet"


EXTENSIONS=(html css cpp py lua c js ts sh md)
blamelines() {
    LINES=0
    for i in * .*; do 
        if [[ "$i" == ".git" ]]; then continue; fi
        if [[ -d "$i" ]]; then
            cd "$i"
            DIR_LINES="$(blamelines)"
            cd ..
            ((LINES+=DIR_LINES))
        else
            FILE_LINES="$(git blame "$i" | grep "$USERNAME" | wc -l)"
            ((LINES+=FILE_LINES))
        fi
    done
    echo $LINES
}
find_name_args=()
for ext in "${EXTENSIONS[@]}"; do
  if [[ ${#find_name_args[@]} -gt 0 ]]; then
    find_name_args+=( -o )
  fi
  find_name_args+=( -name "*.${ext}" )
done

find_args=( \( "${find_name_args[@]}" \) -type f )

PAGE="1"
USERNAME="HrishabhMittal"
LINK="https://github.com"
TOTAL_FILE="$(mktemp)"
echo 0 > "$TOTAL_FILE"
while [[ "$PAGE" != "-1" ]]; do 
    TMP_FILE="$(mktemp)"
    curl -s "$LINK/$USERNAME?page=$PAGE&tab=repositories" --output "$TMP_FILE"
    if grep -q "$END_PAGE" "$TMP_FILE"; then
        rm "$TMP_FILE"
        break
    fi
    ((PAGE++))
    grep -oP 'href="\K[^"]+' "$TMP_FILE" | grep -P "^/$USERNAME/[^/]+$"
    rm "$TMP_FILE"
    sleep 1 # just to be nice to github :)
done | while read -r line; do 
    REPO_LINK="$LINK$line"
    git clone --quiet "$REPO_LINK" repo
    cd repo
    COUNT=$(find . "${find_args[@]}" -exec git blame {} \; | grep "$USERNAME" | wc -l)
    TOTAL="$(cat "$TOTAL_FILE")"
    ((TOTAL+=COUNT))
    echo $TOTAL > "$TOTAL_FILE"
    cd ..
    echo "$REPO_LINK: $COUNT"
    rm repo -rf
done
echo total: "$(cat "$TOTAL_FILE")"
rm "$TOTAL_FILE"

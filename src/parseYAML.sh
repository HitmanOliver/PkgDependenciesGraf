#!/bin/sh

ALLOWED="package_name repo_url repo_mode output_file ascii_tree filter_substring"

FILE_NAME_ERR="Specify the file name"
FILE_EXIST_ERR="No such a file in directory"

if [ $# -lt 1 ]; then
    echo "$FILE_NAME_ERR" >&2
    exit 1
fi

FILEPATH="$1"

if [ ! -f "$FILEPATH" ]; then
    echo "$FILE_EXIST_ERR" >&2
    exit 2
fi

REAL_KEYS=$(yq -r 'keys | .[]' "$FILEPATH")

for RK in $REAL_KEYS; do
    FOUND=0
    for K in $ALLOWED; do
        if [ "$RK" = "$K" ]; then
            FOUND=1
            break
        fi
    done

    if [ $FOUND -eq 0 ]; then
        echo "Unknown key in config: $RK" >&2
        exit 3
    fi

    VALUE=$(yq -r ".$RK" "$FILEPATH")

    case "$RK" in
        ascii_tree)
            case "$VALUE" in
                true|false) ;;
                *) echo "ascii_tree: expected true/false, got: $VALUE" >&2; exit 4 ;;
            esac
            ;;
        repo_mode)
            case "$VALUE" in
                online|locale) ;;
                *) echo "repo_mode: expected online/locale, got: $VALUE" >&2; exit 4 ;;
            esac
            ;;
    esac

    echo "$RK=$VALUE"
done

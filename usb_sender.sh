#!/bin/sh

IMG="/userdata/ums_shared.img"
MNT="/mnt/ums"

STATE_DIR="/tmp/usb_sender"
SEEN_DB="$STATE_DIR/seen.db"
LAST_MTIME="$STATE_DIR/last_mtime"
LOG="$STATE_DIR/sender.log"

UDC="/sys/kernel/config/usb_gadget/rockchip/UDC"
UDC_DEV="fcc00000.dwc3"

PY_UPLOAD="/root/http_upload_file.py"
TARGET_PATH="/from_board"
SERIAL="RK3568BOARD"

mkdir -p "$MNT" "$STATE_DIR"
touch "$SEEN_DB" "$LOG"

log() {
    echo "$(date '+%F %T') $1" | tee -a "$LOG"
}

wait_image_stable() {
    t1="$(stat -c %Y "$IMG" 2>/dev/null)" || return 1
    sleep 3
    t2="$(stat -c %Y "$IMG" 2>/dev/null)" || return 1
    [ "$t1" = "$t2" ]
}

file_sig() {
    f="$1"
    name="$(basename "$f")"
    size="$(stat -c %s "$f" 2>/dev/null)"
    mtime="$(stat -c %Y "$f" 2>/dev/null)"
    echo "${name}|${size}|${mtime}"
}

safe_mount() {
    mount | grep " $MNT " >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        mount -o loop "$IMG" "$MNT"
        return $?
    fi
    return 0
}

safe_umount() {
    mount | grep " $MNT " >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        umount "$MNT"
    fi
}

replug_usb() {
    echo "" > "$UDC"
    sleep 1
    echo "$UDC_DEV" > "$UDC"
}

log "[start] usb sender started"

while true
do
    CUR_MTIME="$(stat -c %Y "$IMG" 2>/dev/null)"
    OLD_MTIME="$(cat "$LAST_MTIME" 2>/dev/null)"

    if [ -n "$CUR_MTIME" ] && [ "$CUR_MTIME" != "$OLD_MTIME" ]; then
        log "[detect] image changed"

        if ! wait_image_stable; then
            log "[skip] image not stable yet"
            sleep 3
            continue
        fi

        if ! safe_mount; then
            log "[error] mount failed"
            sleep 5
            continue
        fi

        FOUND_NEW=0
        SENT_OK=0

        for f in "$MNT"/*
        do
            [ -f "$f" ] || continue

            sig="$(file_sig "$f")"
            grep -Fxq "$sig" "$SEEN_DB"
            if [ $? -ne 0 ]; then
                FOUND_NEW=1
                name="$(basename "$f")"
                log "[new] $name"

                python3 "$PY_UPLOAD" "$f" "$TARGET_PATH" "$SERIAL"
                if [ $? -eq 0 ]; then
                    echo "$sig" >> "$SEEN_DB"
                    SENT_OK=1
                    log "[sent] $name"
                else
                    log "[fail] $name"
                fi
            fi
        done

        sync
        safe_umount

        if [ "$FOUND_NEW" -eq 1 ] && [ "$SENT_OK" -eq 1 ]; then
            log "[usb] replug"
            replug_usb
        else
            log "[skip] no new files sent"
        fi

        echo "$CUR_MTIME" > "$LAST_MTIME"
    fi

    sleep 5
done

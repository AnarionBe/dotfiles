#!/usr/bin/env bash
# Module média pour waybar.
# Lit les métadonnées MPRIS via playerctl et émet du JSON en continu
# (un objet par ligne), consommé par les modules custom/media*.
#
# Usage: mediaplayer.sh [info|toggle|prev|next]
#   info   -> titre / artiste + icône du lecteur
#   toggle -> icône play/pause du bouton central
#   prev / next -> icônes des boutons, masquées si aucun lecteur

set -uo pipefail

# Le script tourne en flux continu pour waybar : il doit mourir avec lui,
# sinon chaque redémarrage de la barre laisse une instance orpheline.
PARENT=$PPID
PCTL_PID=""

cleanup() {
    [[ -n "$PCTL_PID" ]] && kill "$PCTL_PID" 2>/dev/null
    exit 0
}
trap cleanup EXIT INT TERM

( while kill -0 "$PARENT" 2>/dev/null; do sleep 5; done; kill -TERM "$$" 2>/dev/null ) &

SEP=$'\x1f'
MAX_LEN=45
MODE="${1:-info}"

pango_escape() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

player_icon() {
    case "${1,,}" in
        *spotify*)               printf '' ;;
        *ytmdesktop*|*youtube*)  printf '󰗃' ;;
        *firefox*)               printf '󰈹' ;;
        *chrom*|*brave*)         printf '' ;;
        *vlc*|*mpv*|*celluloid*) printf '' ;;
        *)                       printf '' ;;
    esac
}

truncate_text() {
    local s="$1"
    if (( ${#s} > MAX_LEN )); then
        printf '%s…' "${s:0:$((MAX_LEN - 1))}"
    else
        printf '%s' "$s"
    fi
}

emit_empty() {
    printf '{"text":"","tooltip":"","class":"stopped"}\n'
}

emit_info() {
    local status="$1" player="$2" artist="$3" title="$4" album="$5"

    if [[ "$status" == "Stopped" || ( -z "$title" && -z "$artist" ) ]]; then
        emit_empty
        return
    fi

    local label class tooltip
    [[ "$status" == "Playing" ]] && class="playing" || class="paused"

    if [[ -n "$artist" ]]; then
        label="$artist — $title"
    else
        label="$title"
    fi

    tooltip="<b>$(pango_escape "$title")</b>"
    [[ -n "$artist" ]] && tooltip+=$'\n'"$(pango_escape "$artist")"
    [[ -n "$album" ]] && tooltip+=$'\n'"<i>$(pango_escape "$album")</i>"
    tooltip+=$'\n\n'"$(pango_escape "$player") · $status"

    jq -cn --unbuffered \
        --arg text "$(player_icon "$player")  $(pango_escape "$(truncate_text "$label")")" \
        --arg tooltip "$tooltip" \
        --arg class "$class" \
        --arg alt "$status" \
        '{text:$text, tooltip:$tooltip, class:$class, alt:$alt}'
}

emit_toggle() {
    case "$1" in
        Playing) printf '{"text":"","tooltip":"Pause","class":"playing"}\n' ;;
        Paused)  printf '{"text":"","tooltip":"Lecture","class":"paused"}\n' ;;
        *)       emit_empty ;;
    esac
}

# Bouton statique (précédent / suivant) : visible seulement si un lecteur répond.
emit_button() {
    local status="$1" icon="$2" tooltip="$3"
    case "$status" in
        Playing|Paused) printf '{"text":"%s","tooltip":"%s","class":"media-btn"}\n' "$icon" "$tooltip" ;;
        *)              emit_empty ;;
    esac
}

follow_status_button() {
    local icon="$1" tooltip="$2"
    follow_status_with() { emit_button "$1" "$icon" "$tooltip"; }
    follow_status follow_status_with
}

follow_status() {
    while true; do
        exec 3< <(stdbuf -oL playerctl --follow status 2>/dev/null)
        PCTL_PID=$!
        while read -r status <&3; do
            "$@" "$status"
        done
        exec 3<&-
        emit_empty
        sleep 2
    done
}

case "$MODE" in
    info)
        while true; do
            exec 3< <(stdbuf -oL playerctl --follow metadata \
                --format "{{status}}${SEP}{{playerName}}${SEP}{{artist}}${SEP}{{title}}${SEP}{{album}}" \
                2>/dev/null)
            PCTL_PID=$!
            while IFS="$SEP" read -r status player artist title album <&3; do
                emit_info "$status" "$player" "$artist" "$title" "${album:-}"
            done
            exec 3<&-
            emit_empty
            sleep 2
        done
        ;;
    toggle)
        follow_status emit_toggle
        ;;
    prev)
        follow_status_button "" "Titre précédent"
        ;;
    next)
        follow_status_button "" "Titre suivant"
        ;;
    *)
        echo "usage: ${0##*/} [info|toggle|prev|next]" >&2
        exit 1
        ;;
esac

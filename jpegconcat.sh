#!/bin/sh

# jpegconcat.sh
#
# (c) 2016 Rowan Thorpe
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

scriptname=`basename "$0"`
vertmode=0
jpegtran_exec='./jpegtran'
outfile='/dev/stdout'

usage() {
    cat <<EOH
Usage: $scriptname [OPTIONS] FILE [FILE...]

Losslessly concatenate jpeg files. Requires jpegtran compiled from latest version of ijg jpeg
source, patched with the 'droppatch' from jpegclub.org

Although arbitrary (possibly different) image-sizes are fine, probably a degree of consistency
is needed between their parameters (compression, etc). I have only tested it for images
with identical parameters.

OPTIONS
 -h : this help output
 -H : concatenate horizontally `test 1 -eq $vertmode || printf '(default)'`
 -V : concatenate vertically `test 0 -eq $vertmode || printf '(default)'`
 -e : jpegtran executable (default: ${jpegtran_exec})
 -o : output file (default: ${outfile})
EOH
}

die() {
    printf "$@" | sed -e "s/^/${scriptname}: /" >&2
    exit 1
}

die_u() {
    usage >&2
    printf '\n' >&2
    die "$@"
}

while test $# -ne 0; do
    case "$1" in
        -h)
            usage
            exit 0
            ;;
        -H)
            vertmode=0
            shift
            ;;
        -V)
            vertmode=1
            shift
            ;;
        -e)
            jpegtran_exec="$2"
            shift 2
            ;;
        -o)
            outfile="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            die_u 'bad optflag "%s"\n' "$1"
            ;;
        *)
            break
            ;;
    esac
done

trap 'rm -f "$bufferfile" "$pivotfile" 2>/dev/null' EXIT
bufferfile=`mktemp` || die 'failed to create temp bufferfile\n'
pivotfile=`mktemp` || die 'failed to create temp pivotfile\n'

cp "$1" "$bufferfile"
shift

while test $# -ne 0; do
    orig_size=`file -b "$bufferfile" | sed -e 's/^.*, *\([^,]\+\),[^,]\+$/\1/'`
    orig_width=`printf '%s\n' "$orig_size" | cut -dx -f1`
    orig_height=`printf '%s\n' "$orig_size" | cut -dx -f2`
    new_size=`file -b "$1" | sed -e 's/^.*, *\([^,]\+\),[^,]\+$/\1/'`
    new_width=`printf '%s\n' "$new_size" | cut -dx -f1`
    new_height=`printf '%s\n' "$new_size" | cut -dx -f2`

    if test 1 -eq $vertmode; then
        if test $orig_width -gt $new_width; then
            final_width=$orig_width
        else
            final_width=$new_width
        fi
        final_height=`expr $orig_height + $new_height`
    else
        if test $orig_height -gt $new_height; then
            final_height=$orig_height
        else
            final_height=$new_height
        fi
        final_width=`expr $orig_width + $new_width`
    fi
    cropsize=${final_width}x$final_height
    if test 1 -eq $vertmode; then
        dropsize=+0+$orig_height
    else
        dropsize=+${orig_width}+0
    fi

    $jpegtran_exec -copy all -crop $cropsize -outfile "$pivotfile" "$bufferfile"
    $jpegtran_exec -copy all -drop $dropsize "$1" -outfile "$bufferfile" "$pivotfile"
    shift
done
cat "$bufferfile" >"$outfile"

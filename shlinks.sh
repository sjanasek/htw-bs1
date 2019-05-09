#!/usr/bin/env bash

# Exit if any command fails

set -e

scriptname="$(basename $0)" #basename: strip directory and suffix from filenames
print_help() {
	echo "$scriptname [-s|--soft] [-h|--hard] <filename>"
	echo ""
	echo "  --help      Show this help"
	echo "  -s, --soft  Search for soft links to <filename>"
	echo "  -h, --hard  Search for hard links to <filename>"
}

# Print help if no argument is given
if [[ $# -lt 1 ]]; then

	print_help

	exit 1

fi

soft=0
hard=0

while [[ $# -gt 0 ]]; do

	case "$1" in
	-sh | -hs)
		soft=1
		hard=1
		shift
		;;
	-s | --soft)
		soft=1
		shift
		;;
	-h | --hard)
		hard=1
		shift
		;;
	--help)
		print_help
		exit 0
		;;
	*)
		break
		;;
	esac
done

# Default to -sh if neither option is set

if [[ "$soft" == "0" && "$hard" == "0" ]]; then
	soft=1
	hard=1
fi

# Only a single parameter may be left now (<filename>)

# If not then we have invalid, additional options

if [[ $# -gt 1 ]]; then
	echo "Unknown option: $1"
	echo ""
	print_help
	exit 1
fi

filename="$1"

if [[ -z "$filename" ]]; then
	echo "Missing filename parameter!"
	exit 1
fi

# Returns the inode number of the given file

inode() {
	echo "$(stat --format='%i' $1)"
}

# The status code is truthy when the file at path $1

# is a symlink pointing to the file at (absolute!) path $2

symlink_match() {
	[[ "$soft" == "1" && -L "$1" && "$(readlink -f $1)" == "$2" ]]
	return $? #last status code of an exit command
}

# The status code is truthy when the file at path $1

# is a hardlink of the file at path $2

hardlink_match() {
	[[ "$hard" == "1" && "$(inode $1)" == "$2" ]]
	return $?
}

# Resolve $filename in case it's a symlink itself, otherwise we don't have the
# print0 : This allows file names that contain  newlines  or  other
# types  of  white space to be correctly interpreted by programs that process the find output
# read -d: used to terminate the input line, rather than newline
# -r:backslash does not act as an escape character. The backslash is considered to be part of the line. 
# In particular, a backslash-newline pair may not be used as a line continuation.

absolute_filename="$(realpath $filename)"
filename_inode="$(inode $filename)"
find . -print0 | while read -d '' -r f; do
	if symlink_match "$f" "$absolute_filename"; then
			echo "Symbolic Link: " "$f"
	fi

	if
	hardlink_match "$f" "$filename_inode"; then
			echo "Hard Link" "$f"
	fi
done
exit 0
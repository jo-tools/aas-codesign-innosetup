#! /bin/bash
#
# pfx-codesign-wine.sh [FILE (such as called from wine)]
# This Script needs to be called from pfx-codesign.bat.
# The Batch Script waits for FILE.signed until it exits.
# FILE.signed contains the exit code of the codesigning.

# InnoSetup signed per file ($f)
# The Parameter will be a Windows style path in Quotes.
# Let's convert that to the corresponding Linux path.
# The reason we're doing this manually is that "winepath"
# is slow (it starts wine) and noisy when emulated (arm64).
FILE=$1

# Remove surrounding quotes
FILE=${FILE//\"/}

# Remove extended-length path prefix (InnoSetup 7 may pass
# such paths, e.g. if the path is 260 characters or longer)
if [[ $FILE == '\\?\UNC\'* ]]; then
	FILE="\\\\${FILE:8}"  # \\?\UNC\server\share -> \\server\share
elif [[ $FILE == '\\?\'* ]]; then
	FILE="${FILE:4}"      # \\?\Z:\path -> Z:\path
fi

# Replace Windows drive letter at the beginning
if [[ $FILE =~ ^[Zz]:\\ ]]; then
	FILE="/${FILE:3}"  # Z:\ is the root / of the Docker Container
elif [[ $FILE =~ ^([A-Ya-y]):\\ ]]; then
	# other drives (e.g. C:\) are located in the wine prefix
	FILE="${WINEPREFIX:-/root/.wine}/dosdevices/${BASH_REMATCH[1],,}:/${FILE:3}"
fi

# Replace backslashes with forward slashes
FILE=${FILE//\\//}

# Call pfx-codesign.sh to sign the file
/usr/local/bin/pfx-codesign.sh "${FILE}"
PFX_CODESIGN_RESULT=$?

# Write FILE.signed (atomically) with the exit code
echo "${PFX_CODESIGN_RESULT}" > "${FILE}.signed.tmp"
mv -f "${FILE}.signed.tmp" "${FILE}.signed"

exit $PFX_CODESIGN_RESULT

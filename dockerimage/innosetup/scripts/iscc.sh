#!/bin/sh
#
# iscc.sh '[InnoSetup Parameters]'
#
# Note: The Parameters are intentionally passed on unquoted ($*),
#       so that they are being evaluated by the shell running the
#       temporary script (e.g. quoted "/SAAS=... \$f" parameters).

ISCC_EXE="${ISCC_EXE:-/root/.wine/drive_c/Program Files/Inno Setup 7/ISCC.exe}"
ISCC_RUN=$(mktemp /tmp/iscc_run.XXXXXX) || exit 1

# Create temporary script to execute wine -> ISCC.exe
# Note: printf (instead of echo) so that backslashes in Windows paths
#       are not interpreted as escape sequences (such as \t, \n)
printf '%s\n' '#!/bin/sh' > "${ISCC_RUN}"
printf '%s ' "wine \"${ISCC_EXE}\"" $* >> "${ISCC_RUN}"
printf '\n' >> "${ISCC_RUN}"
chmod 755 "${ISCC_RUN}"

# Run script
"${ISCC_RUN}"
ISCC_RESULT=$?

# Cleanup
rm -f "${ISCC_RUN}"

# Result
exit $ISCC_RESULT

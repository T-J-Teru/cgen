#!/bin/sh

# Script to wrap around starting CGEN.
#
# cgen.sh [ OPTIONS FOR THIS SCRIPT ]
#         [ -- ]
#         [ CGEN TOOL SCRIPT ]
#         [ TOOL SCRIPT OPTIONS ]
#
# OPTIONS FOR THIS SCROPT
# =======================
#
# --guile PATH_TO_GUILE
#
# Use PATH_TO_GUILE as the guile executable to use.  Otherwise this
# script will just use the first guile in your $PATH.
#
# --verbose
#
# Have this script report the full command line to invokes to run the
# actual guile process.
#
# CGEN TOOL SCRIPT
# ================
#
# The full path to the scheme script to load that is the CGEN tool to
# be run.
#
# The optional `--` can be used to separate the OPTIONS FOR THIS
# SCRIPT from the CGEN TOOL SCRIPT path.  If this is missing then this
# script will assume that the first string that doesn't look like an
# option for this script is the path to the cgen tool script.
#
# TOOL SCRIPT OPTIONS
# ===================
#
# All remaining command line content is forwarded unchanged to the
# guile process, and will be consumed by the CGEN TOOL SCRIPT.
#

# Display a usage message.
usage () {
    echo "cgen.sh [ OPTIONS FOR THIS SCRIPT ]"
    echo "        [ -- ]"
    echo "        [ PATH TO CGEN TOOL SCRIPT ]"
    echo "        [ TOOL SCRIPT OPTIONS ]"
    echo ""
    echo "TODO: Write more here."

    exit 0
}

error () {
    msg="$1"
    echo "ERROR: ${msg}"
    exit 1
}

GUILE_PATH=
VERBOSE=no

#
# Command line processing.
until
    opt=$1
    case ${opt} in
        --guile)
            shift
            GUILE_PATH=$(realpath -m $1)
            ;;

        --verbose)
            VERBOSE=yes
            ;;

        --help|-h)
            usage
            ;;

        --)
            # This indicates the end of the options for this script.
            # The first thing after this is the CGEN tool script.
            shift
            break
            ;;

        *)
            # Found something we don't understand.  We assume this is
            # the CGEN tool script, so stop processing command line
            # arguments, but leave the script as the first argument.
            break
            ;;
    esac

    # The condition for the 'until' loop.
    [ "x${opt}" = "x" ]
do
    shift
done

TOOL_SCRIPT=$1
if [ -z "${TOOL_SCRIPT}" ]; then
    error "missing path to CGEN tool script"
fi
shift

if [ ! -e "${TOOL_SCRIPT}" ]; then
    error "CGEN tool script '${TOOL_SCRIPT}' not found"
fi

if [ ! -z "${GUILE_PATH}" ]; then
    if [ ! -e "${GUILE_PATH}"]; then
        error "guile not found: ${GUILE_PATH}"
    fi
else
    GUILE_PATH=$(which guile 2>/dev/null)
    if [ -z "${GUILE_PATH}" ]; then
        error "no guile found in \$PATH"
    fi
fi

GUILE_AUTO_COMPILE=0
export GUILE_AUTO_COMPILE

echo "APB: About to execute:"
echo "${GUILE_PATH} -l /home/andrew/projects/cgen/cgen/guile.scm -s ${TOOL_SCRIPT} $@"
echo
echo
echo

exec ${GUILE_PATH} -l /home/andrew/projects/cgen/cgen/guile.scm -s ${TOOL_SCRIPT} "$@"

exit 1

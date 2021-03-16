#!/bin/sh

# Copyright (C) 2021
# This file is part of CGEN.
# See file COPYING.CGEN for details.

# Script to wrap around starting CGEN.
#
#   cgen.sh [ OPTIONS FOR THIS SCRIPT ]
#           [ -- ]
#           [ CGEN TOOL SCRIPT ]
#           [ TOOL SCRIPT OPTIONS ]
#
# Run with --help to get a full list of the available options.

#
# Display a usage message and exit the script with return value 0.
usage () {
    echo "cgen.sh [ OPTIONS FOR THIS SCRIPT ]"
    echo "        [ -- ]"
    echo "        [ PATH TO CGEN TOOL SCRIPT ]"
    echo "        [ TOOL SCRIPT OPTIONS ]"
    echo ""
    echo "OPTIONS FOR THIS SCRIPT:"
    echo "========================"
    echo ""
    echo "--guile PATH_TO_GUILE"
    echo ""
    echo "Use PATH_TO_GUILE as the guile executable to use.  Otherwise this"
    echo "script will just use the first guile in your \$PATH."
    echo ""
    echo " --verbose"
    echo ""
    echo "Have this script report the full command line to invokes to run the"
    echo "actual guile process."
    echo ""
    echo "--compile"
    echo ""
    echo "This option only has an effect for guile 2.x or guile 3.x.  When"
    echo "this flag is passed then CGEN will be compiled.  This will help"
    echo "highlight errors in the code, currently this might not work."
    echo ""
    echo "NOTE: After using --compile, if you with to run in non-compile mode you will"
    echo "      need to manually delete your guile compilation cache as guile's"
    echo "      auto-compile mechanism is known to be broken with regards to dependency"
    echo "      tracking in all versions of guile up to 3.0.2 (and probably later)."
    echo "      Failure to delete the cache can result in guile reusing stale,"
    echo "      pre-compiled code."
    echo ""
    echo "PATH TO CGEN TOOL SCRIPT:"
    echo "========================="
    echo ""
    echo "The full path to the scheme script to load that is the CGEN tool to"
    echo "be run."
    echo ""
    echo "The optional `--` can be used to separate the OPTIONS FOR THIS"
    echo "SCRIPT from the CGEN TOOL SCRIPT path.  If this is missing then this"
    echo "script will assume that the first string that doesn't look like an"
    echo "option for this script is the path to the cgen tool script."
    echo ""
    echo "TOOL SCRIPT OPTIONS:"
    echo "===================="
    echo ""
    echo "All remaining command line content is forwarded unchanged to the"
    echo "guile process, and will be consumed by the CGEN TOOL SCRIPT."
    echo ""

    exit 0
}

#
# Display an error message and exit the script with return value 1.
error () {
    msg="$1"
    echo "ERROR: ${msg}"
    exit 1
}

GUILE_PATH=
VERBOSE=no
COMPILE=0

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

        --compile)
            COMPILE=fresh
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

#
# Validate the tool script path.
TOOL_SCRIPT=$1
if [ -z "${TOOL_SCRIPT}" ]; then
    error "missing path to CGEN tool script"
fi
shift
if [ ! -e "${TOOL_SCRIPT}" ]; then
    error "CGEN tool script '${TOOL_SCRIPT}' not found"
fi

#
# Either validate the user supplied guile path, or find a suitable
# guile executable on the users $PATH.
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

#
# Enable or disable guile's auto-compilation.
GUILE_AUTO_COMPILE=${COMPILE}
export GUILE_AUTO_COMPILE

#
# Figure out where the guile.scm support file can be found, and error
# if it is not where we expect it to be.
SUPPORT_FILENAME="guile.scm"
CGEN_SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CGEN_SUPPORT_PATH="${CGEN_SRC_DIR}/${SUPPORT_FILENAME}"
if test ! -r "${CGEN_SUPPORT_PATH}"; then
    error "${SUPPORT_FILENAME} not found: ${CGEN_SUPPORT_PATH}"
fi

#
# If requested, be verbose about what we're doing.
if test x${VERBOSE} = xyes; then
    echo "${GUILE_PATH} -l ${CGEN_SUPPORT_PATH} -s ${TOOL_SCRIPT}" $(printf "%q " "$@")
fi

#
# Now invoken CGEN.
exec ${GUILE_PATH} -l ${CGEN_SUPPORT_PATH} -s ${TOOL_SCRIPT} "$@"

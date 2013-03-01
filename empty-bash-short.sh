#!/bin/bash
#Declare function before calling in Bash ;)
function PRINT_ERROR_HELP_AND_EXIT {
        echo "Usage : ${0} -a Required -b Required [-c Optional] [-d Optional]"
        exit 1
}

# Think about ourselves
# Set a directory our binary lives in
RUN_DIR="$(dirname ${0})"
# Set just our script or program name (strip of leading directories)
PROG="${0##*/}"
# Get a meta 'short' name, minus any extension
SHORT="${PROG%%.*}"

# Include system config file in /etc/
if [ -f "/etc/${SHORT}/${SHORT}.conf" ]
then
    source /etc/${SHORT}/${SHORT}.conf
fi

# Include system config file in /etc/ without a directory
if [ -f "/etc/${SHORT}.conf" ]
then
    source /etc/${SHORT}.conf
fi

# Include home dir config file
if [ -f "~/.${SHORT}" ]
then
    source ~/.${SHORT}
fi

# Check options for overriding values
while getopts "a:b:c:d:" optionName
 do
        case "$optionName" in
		a) OPT_A="${OPTARG}";;
		b) OPT_B="${OPTARG}";;
		c) OPT_C="${OPTARG}";;
		d) OPT_D="${OPTARG}";;
		[?]) PRINT_ERROR_HELP_AND_EXIT;;
	esac
done

# Make sure our required args A and B are passed
if [ ! "${OPT_A}" ] && [ ! "${OPT_B}" ]
then
    PRINT_ERROR_HELP_AND_EXIT
fi

echo "Running ${0} with OPT_A ${OPT_A} OPT_B ${OPT_B} $(if [ "${OPT_C}" ]; then echo "OPT C is ${OPT_C}"; fi) $(if [ "${OPT_C}" ]; then echo "OPT D is ${OPT_D}"; fi)"


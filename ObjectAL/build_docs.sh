#!/bin/sh

########################################################################
#
#  This script builds the Doxygen documentation for your project
#  and loads the docset into Xcode.
#
#  This script tries to find the Doxygen binary's path. If it fails to
#  find it, add your doxygen path to the list below.
#
########################################################################

set -e
set -u

# Set to 1 to build the latex documentation for PDF generation.
GENERATE_PDF=1

if [ "$SOURCE_ROOT"X = "X" ] || [ "$TEMP_DIR"X = "X" ] || [ "$PROJECT_NAME"X = "X" ]; then
    echo "Error: This script must be run from within XCode's build environment."
    exit 1
fi

PATH=$PATH:$(bash -l -c 'echo $PATH')

# Find Doxygen
DOXYGEN_PATH=/Applications/Doxygen.app/Contents/Resources/doxygen
if [ ! -f "$DOXYGEN_PATH" ]; then
    DOXYGEN_PATH=/opt/local/bin/doxygen
fi
if [ ! -f "$DOXYGEN_PATH" ]; then
    DOXYGEN_PATH=~/bin/doxygen
fi
if [ ! -f "$DOXYGEN_PATH" ]; then
    DOXYGEN_PATH=/usr/local/bin/doxygen
fi
if [ ! -f "$DOXYGEN_PATH" ]; then
    DOXYGEN_PATH=/usr/share/bin/doxygen
fi
if [ ! -f "$DOXYGEN_PATH" ]; then
    DOXYGEN_PATH=/usr/bin/doxygen
fi
if [ ! -f "$DOXYGEN_PATH" ]; then
    DOXYGEN_PATH=/bin/doxygen
fi
if [ ! -f "$DOXYGEN_PATH" ]; then
    echo "Error: Doxygen is not installed or I can't find it (examine build_docs.sh to see where I'm looking)."
    exit 1
fi

DOX_SRC="$TEMP_DIR/doxygen.config"
DOX_TEMP="$TEMP_DIR/doxygen.temp"
DOX_DEST="$TEMP_DIR/doxygen.config"
DOX_SET="$TEMP_DIR/DoxygenDocs.docset"
DOX_NAME="org.doxygen.$PROJECT_NAME"

doxset() {
    subst=${2//\//\\\/}
    subst=${subst//\"/\\\"/}
    set +u
    if [ "$3" != "NO_QUOTES" -a `expr "$subst" : ".*[ '].*"` -gt 0 ]; then
        subst=\"$subst\"
    fi
    set -u
    cat "$DOX_DEST" | sed -E "s/($1[ \t]+=[ \t]*).*$/\1$subst/g" >"$DOX_TEMP"
    mv -f "$DOX_TEMP" "$DOX_DEST"
}

#
# If the config file doesn't exist, run 'doxygen -g <dest>' to create a default file.
#
if ! [ -f "$DOX_SRC" ]; then
    echo doxygen config file does not exist
    mkdir -p $(dirname $DOX_SRC)
    $DOXYGEN_PATH -g "$DOX_SRC"
fi

#
#  Make a copy of the default config
#
if [ "$DOX_SRC" != "$DOX_DEST" ]; then
    cp "$DOX_SRC" "$DOX_DEST"
fi

#
# Customize the settings we want to change
#
doxset PROJECT_NAME         "$PROJECT_NAME"
doxset INPUT                "$SOURCE_ROOT/ObjectAL (iOS)"
doxset IMAGE_PATH           "$SOURCE_ROOT/diagrams"
doxset OUTPUT_DIRECTORY     "$DOX_SET"
doxset DOCSET_BUNDLE_ID     "$DOX_NAME"
doxset RECURSIVE            YES
doxset GENERATE_DOCSET      YES
doxset GENERATE_XML         YES
doxset QUIET                YES
doxset TAB_SIZE             4
doxset QT_AUTOBRIEF         YES
doxset JAVADOC_AUTOBRIEF    YES
doxset FULL_PATH_NAMES      NO
#doxset EXTRACT_ALL          YES
doxset EXTRACT_PRIVATE      NO
doxset EXTRACT_STATIC       NO
doxset ALWAYS_DETAILED_SEC  YES
doxset FILE_PATTERNS        "*.c *.cc *.cxx *.cpp *.c++ *.java *.h *.hh *.hxx *.hpp *.h++ *.m *.mm *.dox" NO_QUOTES
doxset WARN_FORMAT          "\$file:\$line: warning: \$text"

# Set all to YES for generating PDF version
if [ "$GENERATE_PDF" == "1" ]; then
	doxset GENERATE_LATEX       YES
	doxset USE_PDFLATEX         YES
	doxset PDF_HYPERLINKS       YES
else
	doxset GENERATE_LATEX       NO
	doxset USE_PDFLATEX         NO
	doxset PDF_HYPERLINKS       NO
fi

#
#  Run doxygen on the updated config file.
#  Note: doxygen creates a Makefile that does most of the heavy lifting.
#
$DOXYGEN_PATH "$DOX_DEST"

#
#  make will invoke docsetutil. Take a look at the Makefile to see how this is done.
#
make -C "$DOX_SET/html" install

#
#  Load the doc set
#
/usr/bin/osascript -e 'tell application "Xcode" to load documentation set with path "/Users/'$USER'/Library/Developer/Shared/Documentation/DocSets/'$DOX_NAME'.docset"'

exit 0


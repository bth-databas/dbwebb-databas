#!/usr/bin/env bash
#
# Check that the repo contains whats expected.
#
# Exit values:
#  0 on success
#  1 on failure
#



# Name of the script
#SCRIPT=$( basename "$0" )

##
# Message to display for version.
#
version ()
{
    local txt=(
"$SCRIPT version $VERSION"
    )

    printf "%s\\n" "${txt[@]}"
}



##
# Message to display for usage and help.
#
usage ()
{
    local txt=(
"Check that your repo contains the essentials for each part of the course."
"Usage: $SCRIPT check [options] <command> [arguments]"
""
"Command:"
"  labbmiljo                         Checks related to the labbmiljö."
"  kmom01                            Checks related to kmom01."
"  kmom02                            Checks related to kmom02."
"  kmom03                            Checks related to kmom03."
"  kmom04                            Checks related to kmom04."
"  kmom05                            Checks related to kmom05."
"  kmom06                            Checks related to kmom06."
"  Obsolete below"
"  eslint                            Checks executed by eslint."
""
"Options:"
"  --only-this         Check only the specific kmom, no previous ones."
"  --no-branch         Ignore checking branches."
"  --no-color          Do not colourize the output."
"  --help, -h          Print help."
"  --version, -h       Print version."
    )

    printf "%s\\n" "${txt[@]}"
}



##
# Message to display when bad usage.
#
badUsage ()
{
    local message="$1"
    local txt=(
"For an overview of the command, execute:"
"$SCRIPT --help"
    )

    [[ -n $message ]] && printf "%s\\n" "$message"

    printf "%s\\n" "${txt[@]}" >&2
    exit 1
}



##
# Error while processing
#
# @param string $* error message to display.
#
fail ()
{
    local color
    local normal

    color=$(tput setaf 1)
    normal=$(tput sgr0)

    printf "%s $*\\n" "${color}[FAILED]${normal}"
    exit 2
}



##
# Open an url in the default browser
#
# @arg1 the url
#
function openUrl {
    local url="$1"

    #printf "$url\n"
    eval "$WEB_BROWSER \"$url\"" 2>/dev/null &
    sleep 0.5
}



##
# Check if the git tag is between two versions
# >=@arg2 and <@arg3
#
# @arg1 string the path to the dir to check.
# @arg2 string the lowest version number to check.
# @arg3 string the highest version number to check.
#
hasGitTagBetween()
{
    local where="$1"
    local low=
    local high=
    local semTag=

    low=$( getSemanticVersion "$2" )
    high=$( getSemanticVersion "$3" )
    #echo "Validate that tag exists >=$2 and <$3 ."

    local success=false
    local highestTag=0
    local highestSemTag=0

    if [ -d "$where" ]; then
        while read -r tag; do
            semTag=$( getSemanticVersion "$tag" )
            #echo "trying tag $tag = $semTag"
            if [ $semTag -ge $low -a $semTag -lt $high ]; then
                #echo "success with $tag"
                success=
                if [ $semTag -gt $highestSemTag ]; then
                    highestTag=$tag
                    highestSemTag=$semTag
                fi
            fi
        done < <( cd "$where" && git tag )
    fi

    if [ "$success" = "false" ]; then
        printf "$MSG_FAILED Failed to validate tag exists >=%s and <%s." "$2" "$3"
        return 1
    fi

    echo "$highestTag"
}



##
# Convert version to a comparable string
# Works for 1.0.0 and v1.0.0
#
# @arg1 string the version to check.
#
function getSemanticVersion
{
    #local version=${1:1}
    local version=
    
    version=$( echo $1 | sed s/^[vV]// )
    echo "$version" | awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'
}



##
# Check if paths (files and dirs) exists.
#
# param array of paths
#
check_paths ()
{
    local array_name="$1"
    local verbose="$2"
    local paths=("${!array_name}")
    local success=0

    for path in "${paths[@]}"; do
        if [[ -e "$path" ]]; then
            [[ -n "$verbose" ]] && echo "✅ $path"
        else
            [[ -n "$verbose" ]] && echo "❌ $path"
            success=1
        fi
    done

    return $success
}



##
# Check if a set of branches exists in the repo.
#
check_branches ()
{
    local verbose="$1"
    local branches=(
        "main"
        "bth/submit/kmom03"
        "bth/submit/kmom06"
        "bth/submit/kmom10"
    )
    local success=0

    (( NO_BRANCH )) && return 0

    for branch in "${branches[@]}"; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            [[ -n "$verbose" ]] && echo "✅ $branch finns lokalt"
        else
            [[ -n "$verbose" ]] && echo "❌ $branch saknas lokalt"
            success=1
        fi

        # Remote branches
        # if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
        #     [[ -n "$verbose" ]] && echo "✅ $branch finns i din remote"
        # else
        #     [[ -n "$verbose" ]] && echo "❌ $branch saknas i din remote"
        #     success=1
        # fi
    done

    return $success
}



##
# Check paths for a kmom
#
kmom_check_paths ()
{
    local silent="$1"
    local pathArray="$2"
    local success=0

    check_paths "$pathArray" || ([[ ! $silent ]] && check_paths "$pathArray" verbose)
    if (( $? == 0 )); then
        [[ $silent ]] || echo "✅ 😀 $kmom alla kataloger/filer finns på plats."
    else
        [[ $silent ]] || echo "🚫 🔧 $kmom någon katalog/fil saknas eller har fel namn, fixa det."
        success=1
    fi

    return $success
}



##
# Check git repo has a tag
#
kmom_check_tag ()
{
    local silent="$1"
    local kmom="$2"
    local tagMin="$3"
    local tagMax="$4"
    local dir="."
    local success=0
    local res=

    res=$( hasGitTagBetween "$dir" "$tagMin" "$tagMax" )
    if (( $? == 0 )); then
        [[ $silent ]] || echo "✅ 😀 $kmom repot har tagg $res."
    else
        [[ $silent ]] || echo "🚫 🔧 $kmom repot saknar tagg >=$3 and <$4, fixa det."
        success=1
    fi

    return $success
}



##
# Check repo passes eslint
#
kmom_eslint ()
{
    local silent="$1"
    local kmom="$2"
    local path="$3"
    local success=0
    local res=

    (( NO_ESLINT )) && return 0

    res=$( npx eslint "$path" )
    if (( $? == 0 )); then
        [[ $silent ]] || echo "✅ 😀 $kmom eslint passerar."
    else
        [[ $silent ]] || echo "🚫 🔧 $kmom eslint hittade fel, kör eslint mot $path och fixa det."
        if [[ $ESLINT_FIX ]]; then
            [[ $silent ]] || echo "$res" | tail -1
            [[ $silent ]] || printf "\n🙈 🔧 Försöker laga felen med 'eslint --fix och provar igen...\n"
            res=$( npx eslint "$path" --fix )
            res=$( npx eslint "$path" )
            if (( $? == 0 )); then
                [[ $silent ]] || echo "✅ 😀 $kmom eslint passerar."
            fi
        fi
        [[ $VERBOSE ]] && echo "$res"
        success=1
    fi

    return $success
}



##
# Check labs in a kmom
#
kmom_check_lab ()
{
    local silent="$1"
    local kmom="$2"
    local lab="$3"
    local success=0
    local res=

    [[ -d  lab/$lab ]] || return 0
    res=$( cd "lab/$lab" || return 0; node lab "$PASS_LAB" )
    res=$?
    if (( res >= 21 )); then
        [[ $silent ]] || echo "✅ 🙌 $kmom $lab imponerar med ${res}p."
    elif (( res >= 19 )); then
        [[ $silent ]] || echo "✅ 😍 $kmom $lab väl godkänd med ${res}p."
    elif (( res >= 15 )); then
        [[ $silent ]] || echo "✅ 😁 $kmom $lab passerar med ${res}p."
    else
        [[ $silent ]] || echo "🚫 🔧 $kmom $lab med ${res}p passerar inte gränsen för godkänt, fixa det."
        success=1
    fi

    return $success
}



##
# Do tests for a kmom.
#
kmom_do ()
{
    local success=0
    local silent="$1"
    local previous_kmom="$2"
    local kmom="$3"
    local pathArray="$4"
    local versionMin="$5"
    local versionMax="$6"
    local lab="$7"

    if [[ ! $ONLY_THIS ]]; then
        app_"$previous_kmom" silent
        (( $? != 0 )) && success=2
    fi

    kmom_check_paths "$silent" "$pathArray"
    (( $? != 0 )) && success=1

    kmom_check_tag "$silent" "$kmom" "$versionMin" "$versionMax"
    (( $? != 0 )) && success=1

    if [[ $lab ]]; then
        kmom_check_lab "$silent" "$kmom" "$lab"
        (( $? != 0 )) && success=1
    fi

    if [[ ! $silent ]]; then
        if [[ $kmom != "labbmiljo" ]]; then
            kmom_eslint "$silent" "$kmom" "public/"
            (( $? != 0 )) && success=1
        fi
    fi

    # Räkna antalet commits
    # npx http-server och testa de routes som skall fungera

    kmom_summary "$silent" $success "$kmom"
}



##
# Print the summary for each kmom.
#
kmom_summary ()
{
    local silent="$1"
    local success=$2
    local kmom="$3"

    if [[ $silent ]]; then
        if (( success == 0)); then
            echo "✅ 😎 $kmom OK."
        else
            echo "🚫 🔧 $kmom något saknas, kör en egen rapport för $kmom och fixa det."
        fi
    fi
}



##
# Define paths needed for each kmom
#
PATHS_LABBMILJO=(
    ".editorconfig"
    ".gitignore"
    "README.md"
)

PATHS_KMOM01=(
    "kmom/01"
    "kmom/01/README.md"
    "kmom/01/world1"
    "kmom/01/world1/select.sql"
    "kmom/01/world1/task.sql"
)

PATHS_KMOM02=(
    "kmom/02"
    "kmom/02/README.md"
    "kmom/02/world2"
    "kmom/02/world2/join.sql"
    "kmom/02/world2/task.sql"
)

PATHS_KMOM03=(
    "kmom/03"
    "kmom/03/README.md"
    "kmom/03/classic"
    "kmom/03/classic/select.sql"
    "kmom/03/classic/er.pdf"
    "kmom/03/DatabaseExample"
    "kmom/03/DatabaseExample/DatabaseExample.csproj"
    "kmom/03/DatabaseExample/Program.cs"
    "kmom/03/ClassicModels"
    "kmom/03/ClassicModels/ClassicModels.csproj"
    "kmom/03/ClassicModels/Program.cs"
)

PATHS_KMOM04=(
    "kmom/04"
    "kmom/04/README.md"
    "kmom/04/transaction"
    "kmom/04/transaction/create.sql"
    "kmom/04/transaction/insert.sql"
    "kmom/04/transaction/dml.sql"
    "kmom/04/BankExample"
    "kmom/04/BankExample/Program.cs"
    "kmom/04/Bank"
    "kmom/04/Bank/Program.cs"
    "kmom/04/Bank/sql"
    "kmom/04/Bank/sql/setup.sql"
    "kmom/04/Bank/sql/bank.puml"
    "kmom/04/er.pdf"
)

PATHS_KMOM05=(
    "kmom/05"
    "kmom/05/README.md"
    "kmom/05/procedure"
    "kmom/05/procedure/procedure.sql"
    "kmom/05/BankExample"
    "kmom/05/BankExample/Program.cs"
    "kmom/05/Bank"
    "kmom/05/Bank/Program.cs"
    "kmom/05/Bank/sql"
    "kmom/05/Bank/sql/setup.sql"
    "kmom/05/Bank/sql/bank.puml"
    "kmom/05/er.pdf"
)

PATHS_KMOM06=(
    "kmom/06"
    "kmom/06/README.md"
    "kmom/06/trigger"
    "kmom/06/trigger/trigger.sql"
    "kmom/06/Bank"
    "kmom/06/Bank/Program.cs"
    "kmom/06/Bank/sql"
    "kmom/06/Bank/sql/setup.sql"
    "kmom/06/Bank/sql/bank.puml"
    "kmom/06/eshop"
    "kmom/06/eshop/er.pdf"
    "kmom/06/eshop/setup.sql"
    "kmom/06/eshop/schema.pdf"
)

PATHS_KMOM07=(
    "kmom/07"
    "kmom/07/README.md"
    "kmom/07/Eshop"
    "kmom/07/Eshop/Program.cs"
    "kmom/07/Eshop/sql"
    "kmom/07/Eshop/sql/setup.sql"
    "kmom/07/Eshop/sql/proc.sql"
    "kmom/07/Eshop/sql/insert.sql"
)

PATHS_KMOM08=(
    "kmom/08"
    "kmom/08/README.md"
    "kmom/08/Eshop"
    "kmom/08/Eshop/Program.cs"
    "kmom/08/Eshop/sql"
    "kmom/08/Eshop/sql/backup.sql"
    "kmom/08/Eshop/sql/setup.sql"
    "kmom/08/Eshop/sql/proc.sql"
    "kmom/08/Eshop/sql/insert.sql"
)

PATHS_KMOM10=(
    "kmom/10"
    "kmom/10/README.md"
    "kmom/10/Eshop"
    "kmom/10/Eshop/Program.cs"
    "kmom/10/Eshop/sql"
    "kmom/10/Eshop/sql/backup.sql"
    "kmom/10/Eshop/sql/setup.sql"
    "kmom/10/Eshop/sql/proc.sql"
    "kmom/10/Eshop/sql/insert.sql"
)



##
# Check using eslint.
#
app_eslint ()
{
    local target="${1:-public}"

    kmom_eslint "" "" "$target"
    return $?
}



##
# Check the labs.
#
app_lab ()
{
    local success=0
    local res=
    local ret=

    for lab in "$@"; do
        if [[ -d lab/$lab ]]; then
            res=$( cd "lab/$lab" || return 0; node lab "$PASS_LAB" )
            ret=$?
            res=$(echo "$res" | tail -3 | head -1)
            res=${res:2}
        else
            res="directory is missing"
            ret=0
        fi

        [[ $NO_COLOR ]] && res=$( echo "$res" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" )

        if (( ret >= 21 )); then
            echo "✅ 🙌 $lab $res ${ret}p."
        elif (( ret >= 19 )); then
            echo "✅ 😍 $lab $res ${ret}p."
        elif (( ret >= 15 )); then
            echo "✅ 😁 $lab $res ${ret}p."
        else
            echo "🚫 🔧 $lab $res ${ret}p."
            success=1
        fi

    done

    return $success
}



##
# Check a specific part of the course.
#
app_labbmiljo ()
{
    local silent="$1"
    local kmom="Labbmiljö"
    local success=0

    kmom_check_paths "$silent" PATHS_LABBMILJO[@]
    success=$?

    check_branches || ([[ ! $silent ]] && check_branches verbose)
    if (( $? == 0 )); then
        [[ $silent ]] || echo "✅ 😀 $kmom alla branches är på plats."
    else
        [[ $silent ]] || echo "🚫 🔧 $kmom någon branch saknas eller har fel namn, fixa det."
        success=1
    fi

    # Kolla att repot har rätt namn
    # npx http-server ?

    kmom_summary "$silent" $success "$kmom"

    return $success
}



##
# Check a specific kmom.
#
app_kmom01 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="labbmiljo"
    local kmom="kmom01"
    local pathArray="PATHS_KMOM01[@]"
    local versionMin="v1.0.0"
    local versionMax="v2.0.0"
    local lab="lab_01"

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}



##
# Check a specific kmom.
#
app_kmom02 ()
{
    local silent="$1"
    local success=0
    local previous_kmom="kmom01"
    local kmom="kmom02"
    local pathArray="PATHS_KMOM02[@]"
    local versionMin="v2.0.0"
    local versionMax="v3.0.0"
    local lab="lab_02"

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}



##
# Check a specific kmom.
#
app_kmom03 ()
{
    local silent="$1"
    local success=0
    local previous_kmom="kmom02"
    local kmom="kmom03"
    local pathArray="PATHS_KMOM03[@]"
    local versionMin="v3.0.0"
    local versionMax="v4.0.0"
    local lab="lab_03"

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    # kontrollera att PR är korrekt gjord för kmom03

    return $success
}



##
# Check a specific kmom.
#
app_kmom04 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="labbmiljo"
    local kmom="kmom04"
    local pathArray="PATHS_KMOM04[@]"
    local versionMin="v4.0.0"
    local versionMax="v5.0.0"
    local lab="lab_04"

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}



##
# Check a specific kmom.
#
app_kmom05 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="kmom04"
    local kmom="kmom05"
    local pathArray="PATHS_KMOM05[@]"
    local versionMin="v5.0.0"
    local versionMax="v6.0.0"
    local lab="no"

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}



##
# Check a specific kmom.
#
app_kmom06 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="kmom05"
    local kmom="kmom06"
    local pathArray="PATHS_KMOM06[@]"
    local versionMin="v6.0.0"
    local versionMax="v7.0.0"
    local lab=""

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}



##
# Check a specific kmom.
#
app_kmom07 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="no"
    local kmom="kmom07"
    local pathArray="PATHS_KMOM07[@]"
    local versionMin="v7.0.0"
    local versionMax="v8.0.0"
    local lab=""

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}


##
# Check a specific kmom.
#
app_kmom08 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="no"
    local kmom="kmom08"
    local pathArray="PATHS_KMOM08[@]"
    local versionMin="v8.0.0"
    local versionMax="v9.0.0"
    local lab=""

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}


##
# Check a specific kmom.
#
app_kmom10 ()
{
    local success=0
    local silent="$1"
    local previous_kmom="no"
    local kmom="kmom10"
    local pathArray="PATHS_KMOM10[@]"
    local versionMin="v10.0.0"
    local versionMax="v11.0.0"
    local lab=""

    kmom_do "$silent" "$previous_kmom" "$kmom" "$pathArray" "$versionMin" "$versionMax" "$lab"
    res=$?
    (( res != 0 )) && success=$res

    return $success
}



##
# Always have a main
# 
main ()
{
    local command
    local args

    # defaults
    NO_ESLINT=1

    while (( $# ))
    do
        case "$1" in

            --eslint-fix)
                ESLINT_FIX=1
                shift
            ;;

            --help | -h)
                usage
                exit 0
            ;;

            --only-this)
                ONLY_THIS=1
                shift
            ;;

            --no-branch)
                NO_BRANCH=1
                shift
            ;;

            --no-color)
                NO_COLOR=1
                shift
            ;;

            --no-eslint)
                NO_ESLINT=1
                shift
            ;;

            --pass-lab)
                PASS_LAB="-s"
                shift
            ;;

            --verbose | -v)
                VERBOSE=1
                shift
            ;;

            --version)
                version
                exit 0
            ;;

            eslint           \
            | lab            \
            | labbmiljo      \
            | kmom01         \
            | kmom02         \
            | kmom03         \
            | kmom04         \
            | kmom05         \
            | kmom06         \
            | kmom07         \
            | kmom08         \
            | kmom10         \
            )
                if [[ ! $command ]]; then
                    command=$1
                else
                    args+=("$1")
                fi
                shift
            ;;

            -*)
                badUsage "Unknown option '$1'."
            ;;

            *)
                if [[ ! $command ]]; then
                    badUsage "Unknown command '$1'."
                else
                    args+=("$1")
                    shift
                fi
            ;;

        esac
    done

    # Execute the command 
    if type -t app_"$command" | grep -q function; then
        app_"$command" "${args[@]}"
    else
        badUsage "Missing option or command."
    fi
}

main "$@"

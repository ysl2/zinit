#!/usr/bin/env zsh
#
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors
# Copyright (c) 2021-2022 zdharma-continuum and contributors

# FUNCTION: .zinit-any-colorify-as-uspl2 [[[
# Returns ANSI-colorified "user/plugin" string, from any supported
# plugin spec (user---plugin, user/plugin, user plugin, plugin).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
#
# $REPLY - ANSI-colorified "user/plugin" string
.zinit-any-colorify-as-uspl2 () {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    if [[ "$user" = "%" ]]; then
        .zinit-any-to-pid "" $plugin
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--plugins--/OMZP::}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--plugins/OMZP}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--lib--/OMZL::}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--lib/OMZL}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--themes--/OMZT::}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--themes/OMZT}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--/OMZ::}"
        REPLY="${REPLY/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk/OMZ}"
        REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk--modules--/PZTM::}"
        REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk--modules/PZTM}"
        REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk--/PZT::}"
        REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk/PZT}"
        REPLY="${REPLY/(#b)%([A-Z]##)(#c0,1)(*)/%$ZINIT[col-uname]$match[1]$ZINIT[col-pname]$match[2]$ZINIT[col-rst]}"
    elif [[ $user == http(|s): ]]; then
        REPLY="${user}/${plugin}"
    else
        REPLY="${user:+${user}/}${plugin}"
    fi
} # ]]]
# FUNCTION: .zinit-compute-ice [[[
# Computes ICE array
#   - input
#   - static
#   - saved
# taking priorities into account.
# Can also pack resulting ices into ZINIT_SICE (see $2).
# Returns filepath to snippet directory and optional snippet file name (only
# valid if ICE[svn] is not set).
#
# $1 - URL (also plugin-spec)
# $2 - "pack" or "nopack" or "pack-nf" - packing means ICE
#      wins with static ice; "pack-nf" means that disk-ices will
#      be ignored (no-file?)
# $3 - name of output associative array, "ICE" is the default
# $4 - name of output string parameter, to hold path to directory ("local_dir")
# $5 - name of output string parameter, to hold filename ("filename")
# $6 - name of output string parameter, to hold is-snippet 0/1-bool ("is_snippet")
#
# $REPLY - snippet directory filepath
.zinit-compute-ice () {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob typesetsilent warncreateglobal noshortloops
    local ___URL="${1%/}" ___pack="$2" ___is_snippet=0
    local ___var_name1="${3:-ZINIT_ICE}" ___var_name2="${4:-local_dir}" ___var_name3="${5:-filename}" ___var_name4="${6:-is_snippet}"
    local -a ice_order nval_ices
    ice_order=(${(s.|.)ZINIT[ice-list]} ${(@)${(@Akons:|:)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/})
    nval_ices=(${(s.|.)ZINIT[nval-ice-list]} ${(@)${(@)${(@Akons:|:)ZINIT_EXTS[ice-mods]}:#*\'\'*}/(#s)<->-/} svn)
    ___URL="${${___URL#"${___URL%%[! $'\t']*}"}%/}"
    .zinit-two-paths "$___URL"
    local ___s_path="${reply[-4]}" ___s_svn="${reply[-3]}" ___path="${reply[-2]}" ___filename="${reply[-1]}" ___local_dir
    if [[ -d "$___s_path" || -d "$___path" ]]; then
        ___is_snippet=1
    else
        .zinit-any-to-user-plugin "$___URL" ""
        local ___user="${reply[-2]}" ___plugin="${reply[-1]}"
        ___s_path="" ___filename=""
        [[ "$___user" = "%" ]] && ___path="$___plugin"  || ___path="${ZINIT[PLUGINS_DIR]}/${___user:+${___user}---}${___plugin//\//---}"
        .zinit-exists-physically-message "$___user" "$___plugin" || return 1
    fi
    [[ $___pack = pack* ]] && (( ${#ICE} > 0 )) && .zinit-pack-ice "${___user-$___URL}" "$___plugin"
    local -A ___sice
    local -a ___tmp
    ___tmp=("${(z@)ZINIT_SICE[${___user-$___URL}${${___user:#(%|/)*}:+/}$___plugin]}")
    (( ${#___tmp[@]} > 1 && ${#___tmp[@]} % 2 == 0 )) && ___sice=("${(Q)___tmp[@]}")
    if [[ "${+___sice[svn]}" = "1" || -n "$___s_svn" ]]; then
        if (( !___is_snippet && ${+___sice[svn]} == 1 )); then
            +zinit-message "{e} {ice}svn{rst} ice can only be used with snippets"
            return 1
        elif (( !___is_snippet )); then
            builtin print -r -- "Undefined behavior #1 occurred, please report at https://github.com/zdharma-continuum/zinit/issues"
            return 1
        fi
        if [[ -e "$___s_path" && -n "$___s_svn" ]]; then
            ___sice[svn]=""
            ___local_dir="$___s_path"
        else
            if [[ ! -e "$___path" ]]; then
                +zinit-message "{e} No snippet found on paths (1) $___s_path or $___path"
                return 1
            fi
            unset '___sice[svn]'
            ___local_dir="$___path"
        fi
    else
        if [[ -e "$___path" ]]; then
            unset '___sice[svn]'
            ___local_dir="$___path"
        else
            +zinit-message "{e} No snippet found on paths (2) $___s_path or $___path"
            return 1
        fi
    fi
    local ___zinit_path="$___local_dir/._zinit"
    local -A ___mdata
    local ___key
    {
        for ___key in mode url is_release is_release{2..5} ${ice_order[@]}; do
            [[ -f "$___zinit_path/$___key" ]] && ___mdata[$___key]="$(<$___zinit_path/$___key)"
        done
        [[ "${___mdata[mode]}" = "1" ]] && ___mdata[svn]=""
    } 2> /dev/null
    for ___key in ${ice_order[@]}; do
        [[ $___key == (no|)compile ]] && continue
        if (( 0 == ${+ICE[no$___key]} && 0 == ${+___sice[no$___key]} )); then
            continue
        fi
        if (( 1 == ${+ICE[$___key]} && 0 == ${+ICE[no$___key]} && 1 == ${+___sice[no$___key]} )); then
            continue
        fi
        if [[ "$___key" = "svn" ]]; then
            builtin print -r -- '0' >| "$___zinit_path/mode"
            ___mdata[mode]=0
        else
            command rm -f -- "$___zinit_path/$___key"
        fi
        unset "___mdata[$___key]" "___sice[$___key]" "ICE[$___key]"
    done
    local -A ___MY_ICE
    for ___key in mode url is_release is_release{2..5} ${ice_order[@]}; do
        (( ${+___sice[$___key]} + ${${${___pack:#pack-nf*}:+${+___mdata[$___key]}}:-0} )) && ___MY_ICE[$___key]="${___sice[$___key]-${___mdata[$___key]}}"
    done
    ___key=teleid
    [[ "$___pack" = pack-nftid ]] && {
        (( ${+___sice[$___key]} + ${+___mdata[$___key]} )) && ___MY_ICE[$___key]="${___sice[$___key]-${___mdata[$___key]}}"
    }
    : ${(PA)___var_name1::="${(kv)___MY_ICE[@]}"}
    : ${(P)___var_name2::=$___local_dir}
    : ${(P)___var_name3::=$___filename}
    : ${(P)___var_name4::=$___is_snippet}
    return 0
} # ]]]
# FUNCTION: .zinit-countdown [[[
# Displays a countdown 5...4... etc.
#
# $REPLY - 1 if Ctrl-C is pressed, otherwise 0
.zinit-countdown() {
  (( !${+ICE[countdown]} )) && return 0

  builtin emulate -L zsh -o extendedglob ${=${options[xtrace]:#off}:+-o xtrace}
  trap "+zinit-message \"{ehi}ABORTING, the ice {ice}$ice{ehi} not ran{rst}\"; return 1" INT

  local count=5 ice tpe="$1"

  ice="${ICE[$tpe]}"
  [[ $tpe = "atpull" && $ice = "%atclone" ]] && ice="${ICE[atclone]}"
  ice="{b}{ice}$tpe{ehi}:{rst}${ice//(#b)(\{[a-z0-9…–_-]##\})/\\$match[1]}"

  +zinit-message -n "{hi}Running $ice{rst}{hi} ice in...{rst} "

  while (( -- count + 1 )) {
    +zinit-message -n -- "{b}{error}"$(( count + 1 ))"{rst}{…}"
    sleep 1
  }

  +zinit-message -r -- "{b}{error}0 <running now>{rst}{…}"
  return 0
} # ]]]
# FUNCTION: .zinit-exists-physically [[[
# Checks if directory of given plugin exists in PLUGIN_DIR.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-exists-physically() {
  .zinit-any-to-user-plugin "$1" "$2"
  if [[ ${reply[-2]} = % ]]; then
    [[ -d ${reply[-1]} ]] && return 0 || return 1
  else
    [[ -d ${ZINIT[PLUGINS_DIR]}/${reply[-2]:+${reply[-2]}---}${reply[-1]//\//---} ]] \
      && return 0 \
      || return 1
  fi
} # ]]]
# FUNCTION: .zinit-exists-physically-message [[[
# Checks if directory of given plugin exists in PLUGIN_DIR, and outputs error
# message if it doesn't.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-exists-physically-message () {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    builtin setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes
    if ! .zinit-exists-physically "$1" "$2"; then
        .zinit-any-to-user-plugin "$1" "$2"
        if [[ $reply[1] = % ]]; then
            .zinit-any-to-pid "$1" "$2"
            local spec1=$REPLY
            if [[ $1 = %* ]]; then
                local spec2=%${1#%}${${1#%}:+${2:+/}}$2
            elif [[ -z $1 || -z $2 ]]; then
                local spec3=%${1#%}${2#%}
            fi
        else
            integer nospec=1
        fi
        .zinit-any-colorify-as-uspl2 "$1" "$2"
        +zinit-message -n "{e} No such (plugin or snippet) $REPLY"
        [[ $nospec -eq 0 && $spec1 != $spec2 ]] && +zinit-message " (expands to: {file}${spec2#%}{rst})"
        return 1
    fi
    return 0
} # ]]]
# FUNCTION: .zinit-first [[[
# Finds the main file of plugin. There are multiple file name formats, they are
# ordered in order starting from more correct ones, and matched.
# .zinit-load-plugin() has similar code parts and doesn't call .zinit-first() –
# for performance. Obscure matching is done in .zinit-find-other-matches, here
# and in .zinit-load(). Obscure = non-standard main-file naming convention.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-first () {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    .zinit-any-to-pid "$1" "$2"
    .zinit-get-object-path plugin "$REPLY"
    integer ret=$?
    local dname="$REPLY"
    (( ret )) && {
        reply=("$dname" "")
        return 1
    }
    if [[ -e "$dname/$plugin.plugin.zsh" ]]; then
        reply=("$dname/$plugin.plugin.zsh")
    else
        .zinit-find-other-matches "$dname" "$plugin"
    fi
    if [[ "${#reply}" -eq "0" ]]; then
        reply=("$dname" "")
        return 1
    fi
    reply=("$dname" "${reply[-${#reply}]}")
    return 0
} # ]]]
# FUNCTION: .zinit-store-ices [[[
# Saves ice mods in given hash onto disk.
#
# $1 - directory where to create or delete files
# $2 - name of hash that holds values
# $3 - additional keys of hash to store, space separated
# $4 - additional keys of hash to store, empty-meaningful ices, space separated
# $5 – URL, if applicable
# $6 – mode, svn=1, 0=single file
.zinit-store-ices () {
    local ___pfx="$1" ___ice_var="$2" ___add_ices="$3" ___add_ices2="$4"
    local url="$5" mode="$6"
    local -a ice_order nval_ices
    ice_order=(${(s.|.)ZINIT[ice-list]} ${(@)${(@Akons:|:)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/})
    nval_ices=(${(s.|.)ZINIT[nval-ice-list]} ${(@)${(@)${(@Akons:|:)ZINIT_EXTS[ice-mods]}:#*\'\'*}/(#s)<->-/} svn)
    command mkdir -p "$___pfx" && echo '*' > "$___pfx/.gitignore"
    local ___key ___var_name
    for ___key in ${ice_order[@]:#(${(~j:|:)nval_ices[@]})} ${(s: :)___add_ices[@]}; do
        ___var_name="${___ice_var}[$___key]"
        (( ${(P)+___var_name} )) && builtin print -r -- "${(P)___var_name}" >| "$___pfx"/"$___key"
    done
    for ___key in ${nval_ices[@]} ${(s: :)___add_ices2[@]}; do
        ___var_name="${___ice_var}[$___key]"
        if (( ${(P)+___var_name} )); then
            builtin print -r -- "${(P)___var_name}" >| "$___pfx"/"$___key"
        else
            command rm -f "$___pfx"/"$___key"
        fi
    done
    for ___key in url mode; do
        [[ -n "${(P)___key}" ]] && builtin print -r -- "${(P)___key}" >| "$___pfx"/"$___key"
    done
} # ]]]
# FUNCTION: .zinit-two-paths [[[
# Obtains a snippet URL without specification if it is an SVN URL (points to
# directory) or regular URL (points to file), returns 2 possible paths for
# further examination
#
# $REPLY - two filepaths
.zinit-two-paths () {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob typesetsilent warncreateglobal noshortloops
    local dirnameA dirnameB local_dirA local_dirB svn_dirA url1 url2 url=$1
    local -a fileB_there
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    url1=$url
    url2=$url
    .zinit-get-object-path snippet "$url1"
    local_dirA=$reply[-3] dirnameA=$reply[-2]
    [[ -d "$local_dirA/$dirnameA/.svn" ]] && {
        svn_dirA=".svn"
        if { .zinit-first % "$local_dirA/$dirnameA" }; then
            fileB_there=(${reply[-1]})
        fi
    }
    .zinit-get-object-path snippet "$url2"
    local_dirB=$reply[-3] dirnameB=$reply[-2]
    [[ -z $svn_dirA ]] && fileB_there=("$local_dirB/$dirnameB"/*~*.(zwc|md|js|html)(.-DOnN[1]))
    reply=("$local_dirA/$dirnameA" "$svn_dirA" "$local_dirB/$dirnameB" "${fileB_there[1]##$local_dirB/$dirnameB/#}")
} # ]]]

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et foldmarker=[[[,]]] foldmethod=marker

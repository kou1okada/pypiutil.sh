#!/usr/bin/env bash
#
# pypi utility
# Copyright (c) 2021 Koichi OKADA. All rights reserved.
# This script is distributed under the MIT license.
#

source hhs.bash 0.2.0

CACHEDIR="/tmp/.pypiutil_cache"
TTL=3600
MAX_SUMMARY=10

function fetch () # <URL>
#   cat URL using CACHE and TTL.
{
  local cache="$(get_cache "$1")"
	[ -d "$CACHEDIR" ] || mkdir -p "$CACHEDIR"
  if [ ! -e "$cache" ] || (( TTL < $(date +%s) - $(date -r "$cache" +%s ) )); then
    wget -U "$UA_FX" -qO "$cache" "$1"
    printf "%s\t%s\n" "${cache##*/}" "$1" >>"$CACHEDIR/list"
  fi
  cat "$cache"
}

function get_body ()
{
  gawk '/<body>/,/<\/body>/' | tail -n+2 | head -n-1
}

function get_cache () # <ID>
{
  local hash="$(get_hash "$1")"
  echo "$CACHEDIR/$hash"
}

function get_hash () # <ID>
{
  echo -n "$1" | sha512sum | awk '$0=$1'
}

function get_package_description_summary () 
{
  grep package-description__summary \
  | strip_tags
}

function get_packages ()
{
  get_body \
  | strip_tags
}

function strip_tags ()
{
  sed -E 's/<[^>]*>//g;s/^[[:space:]]*//g'
}

function pypiutil_search () # <pattern>
#   Search packages.
{
  local pattern="${1:-.}"
  fetch https://pypi.org/simple/ \
  | get_packages \
  | grep -E "$pattern"
}

function pypiutil_show () # <package>
#   Show package details.
{
  pypiutil_web "$@"
}

function pypiutil_summary () # <package>
#   Show package summary.
{
  local pkg="$1"
  [ "$pkg" ] || { invoke_usage; exit; }
  fetch "https://pypi.org/project/$pkg/" \
  | get_package_description_summary
}

function pypiutil_web () # <package>
#   Show package details with web.
{
  local pkg="$1"
  [ "$pkg" ] || { invoke_usage; exit; }
  local open=( $(type -p cygstart xdg-open) )
  "$open" "https://pypi.org/project/$pkg/"
}

has_subcommand_pypiutil=1

function pypiutil () # <command> [args ...]
#   pypi utility
{
  :
}

invoke_command "$@"

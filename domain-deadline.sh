#!/bin/bash
# The script counts days until Domain expiration date

function error_empty () {
  echo "ERROR: Host not specified
  Usage: $0 example.com"
}

function error_resolve () {
  echo "ERROR: Host $1 can not be resolved
  Usage: $0 example.com"
}

function error_parser() {
  echo "ERROR: Can't parse TLD
  Domain $1 is unknown"
}

function error_whois() {
  echo "ERROR: Can't find information about expiration date for domain $1"
}

function pre_check () {
  if [ -z "$1" ]; then
    error_empty
    exit 1
  fi

  # You need install idn2 tool to convert utf-8 domains name to ascii (президент.рф to xn--d1abbgf6aiiy.xn--p1ai)
  host $(idn2 "$1") &> /dev/null
  result=$?
  if [ "$result" -eq 1 ]; then
    error_resolve $1
    exit 1
  fi
}

function count_days () {
  i_hostname="$1"
  i_hostname_zone=$(expr match "$1" '.*\.\(.*\.*\)')

  # TLD parser
  case "$i_hostname_zone" in
    ru|su|рф)
      i_grep="paid-till"
      ;;
    com|digital)
      i_grep="Registry Expiry Date"
      ;;
    *)
      error_parser $i_hostname_zone
      exit 1
      ;;
  esac

  # Subdomain checks
  i_result=1
  i_hostname_tmp="$i_hostname"

  while [ "$i_result" -ne 0 ]; do

    whois $i_hostname_tmp | grep -i "$i_grep" &> /dev/null
    i_result=$?

    if [ "$i_result" -eq 1 ]; then
      i_hostname_tmp=$(echo $i_hostname_tmp | awk -F\. '{sub($1 FS,"")}7')
      if [ -z "$i_hostname_tmp" ]; then
        error_whois $i_hostname
        exit 1
      fi
    fi

  done

  # Count days before expiration
  i_deadline=$(date -d $(whois $i_hostname_tmp | grep -i "$i_grep" | awk '{print $NF}') +"%s")
  i_today=$(LANG=en_us_88591; date +"%s")

  i_days=$(($(($i_deadline-$i_today))/86400)) # 86400 = 60*60*24

  echo "$i_days"
}

################################################################################
# MAIN                                                                         #
################################################################################

pre_check "$1"
count_days "$1"

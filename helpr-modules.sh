#!/bin/bash

# HELP FUNCTION FOR GUIDE
banner() {
  #echo "test"
  echo -e "██   ██ ███████ ██      ██████  ██████  \n██   ██ ██      ██      ██   ██ ██   ██ \n███████ █████   ██      ██████  ██████  \n██   ██ ██      ██      ██      ██   ██ \n██   ██ ███████ ███████ ██      ██   ██ v1.0\n                         --- BY RUDRADEV PAL\n"
}

help() {
  banner
  echo "Usage: helpr <OPERATION> [ -k kubeconfig ] [ -n namespace ]" 1>&2
}

# GET KUBECONFIGS CREATED BY USER - ONSITE + LOCAL
get_kubeconfigs(){
  ONSITE_KUBECONFIG=$(ls -l kubeconfig/onsite|awk '{print $9}'| tail -n +2)
  LOCAL_KUBECONFIG=$(ls -l kubeconfig/local|awk '{print $9}'| tail -n +2)

  echo -e "ENVIRONMENT \t KUBECONFIG"
  echo -e "------------ \t -----------"
  while IFS= read -r line ;
  do
     echo -e "ONSITE\t\t "$line;
  done <<< "$ONSITE_KUBECONFIG"

  while IFS= read -r line ;
  do
     echo -e "LOCAL\t\t "$line;
  done <<< "$LOCAL_KUBECONFIG"
}

# GET LOCAL LASTEST VERSIONS
get_latest_versions(){
  local OPTIND
  while getopts ":k:n:" options; do
    case "${options}" in
      k)
         KUBECONFIG=${OPTARG};;
      n)
         NAMESPACE=${OPTARG};;
      :)
         echo -e "Error: helpr versions - please provide correct flags\n"
         echo -e "helpr versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nversions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run "helpr kubeconfig".\n  -n        Specify the namespace of the target environment."
         exit 1;;
      *)
         echo -e "Error: helpr versions - please provide correct flags\n"
         echo -e "helpr versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nversions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run "helpr kubeconfig".\n  -n        Specify the namespace of the target environment."
         exit 1;;
    esac
  done

  if [[ -z "$KUBECONFIG" || -z "$NAMESPACE" ]]
  then
    echo -e "Error: helpr versions - please provide correct flags\n"
    echo -e "helpr versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nversions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run "helpr kubeconfig".\n  -n        Specify the namespace of the target environment."
    exit 1
  fi



  ARTIFACTS=($(jq 'keys' artifacts-map.json| tr -d '[],"'))
  OUTPUT=$(cat test.json)
  # OUTPUT=$(kubectl get cm version -n  $)

  for i in "${ARTIFACTS[@]}"
  do
    ARTIFACT_NAME=$(jq '."'$i'"' artifacts-map.json| sed -r 's/\"//g')
    VERSION=$(echo "$OUTPUT"|grep $i| tail -1| awk -F': ' '{print $2}'| sed -r 's/\"//g'|sed -r 's/,//g')
    echo $ARTIFACT_NAME:$VERSION
  done

}

# JUST A SAMPLE FUNCTION
test(){
  local OPTIND
  while getopts ":k:n:t:" options; do
    case "${options}" in
      k)
         KUBECONFIG=${OPTARG};;
      n)
         NAMESPACE=${OPTARG};;
      t)
         TEST=${OPTARG};;
      :)
         echo -e "Error: helpr requires an argument.\n"
         echo -e "For full guide run helpr help"
         exit 1;;
      *)
         echo -e "Error: helpr requires an argument.\n"
         echo -e "For full guide run $0 help"
         exit 1;;
    esac
  done
  echo $KUBECONFIG-$NAMESPACE-$TEST
}


# MAIN SSWITCH CASE
case "$1" in
  kubeconfig)
    get_kubeconfigs;;
  versions)
    get_latest_versions "${@:2}" ;;
  help)
    help;;
  *)
    echo -e "Error: helpr requires an operation.\n"
    echo -e "For full guide run helpr help"
    exit 1;;
esac

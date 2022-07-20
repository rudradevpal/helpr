#!/bin/bash

VERSION="v1.1"

version(){
  echo "$VERSION"
}

# HELP FUNCTION FOR GUIDE
banner() {
  echo "test"
  #echo -e "██   ██ ███████ ██      ██████  ██████  \n██   ██ ██      ██      ██   ██ ██   ██ \n███████ █████   ██      ██████  ██████  \n██   ██ ██      ██      ██      ██   ██ \n██   ██ ███████ ███████ ██      ██   ██ $VERSION\n                         --- BY RUDRADEV PAL\n"
}

help() {
  banner
  echo "Usage: helpr <OPERATION> [ -k kubeconfig ] [ -n namespace ]" 1>&2
}

update-check(){
  REMOTE_VERSION=$(curl -s https://raw.githubusercontent.com/rudradevpal/helpr/main/helpr-modules.sh |grep VERSION= |head -n 1| sed -r 's/\"//g'|sed -r 's/VERSION=//g')

  if [[ ! -z "$REMOTE_VERSION" && "$REMOTE_VERSION" != "$VERSION" ]]
  then
    echo "Update available: "$REMOTE_VERSION
  else
    echo "Helpr is up to date"
  fi
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
  local ONSITE_ENV=false
  while getopts ":k:n:o" options; do
    case "${options}" in
      k)
         KUBECONFIG=${OPTARG};;
      n)
         NAMESPACE=${OPTARG};;
      o)
         ONSITE_ENV=true;;
      :)
         echo -e "Error: helpr get-versions - please provide correct flags\n"
         echo -e "helpr get-versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nget-versions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment."
         exit 1;;
      *)
         echo -e "Error: helpr het-versions - please provide correct flags\n"
         echo -e "helpr get-versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nget-versions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment."
         exit 1;;
    esac
  done

  if [[ -z "$KUBECONFIG" || -z "$NAMESPACE" ]]
  then
    echo -e "Error: helpr get-versions - please provide correct flags\n"
    echo -e "helpr get-versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nget-versions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment."
    exit 1
  fi

  ARTIFACTS=($(jq '.artifacts|keys' config.json | tr -d '[],"'))
  if [ "$ONSITE_ENV" = true ]
  then
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    OUTPUT=$(gcloud compute ssh --zone=northamerica-northeast1-a --project cio-nc-cloud-core-np-28a0c4 artifactory --tunnel-through-iap --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get cm version -n '$NAMESPACE' -o json --kubeconfig="helpr/'"$KUBECONFIG"'";'| jq '.data')
  else
    OUTPUT=$(kubectl get cm version -n $NAMESPACE -o json --kubeconfig="kubeconfig/local/"$KUBECONFIG | jq '.data';)
  fi

  for i in "${ARTIFACTS[@]}"
  do
    ARTIFACT_NAME=$(jq '."'$i'"' artifacts-map.json| sed -r 's/\"//g')
    VERSION=$(echo "$OUTPUT"|grep $i| tail -1| awk -F': ' '{print $2}'| sed -r 's/\"//g'|sed -r 's/,//g')
    if [[ ! -z "$VERSION" ]]
    then
      echo $ARTIFACT_NAME:$VERSION
    fi
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
  get-kubeconfigs)
    get_kubeconfigs;;
  get-versions)
    get_latest_versions "${@:2}" ;;
  version)
    version;;
  update-check)
    update-check;;
  help)
    help;;
  *)
    echo -e "Error: helpr requires an operation.\n"
    echo -e "For full guide run helpr help"
    exit 1;;
esac

#!/bin/bash

VERSION="v1.2"

version(){
  echo "$VERSION"
}

# HELP FUNCTION FOR GUIDE
banner() {
  #echo "test"
  echo -e "██   ██ ███████ ██      ██████  ██████  \n██   ██ ██      ██      ██   ██ ██   ██ \n███████ █████   ██      ██████  ██████  \n██   ██ ██      ██      ██      ██   ██ \n██   ██ ███████ ███████ ██      ██   ██ $VERSION\n                         --- BY RUDRADEV PAL\n"
}

help() {
  banner
  echo "Usage: helpr <OPERATION> [ -k kubeconfig ] [ -n namespace ]" 1>&2
}

update-check(){
  REMOTE_VERSION=$(curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/rudradevpal/helpr/main/helpr-modules.sh |grep VERSION= |head -n 1| sed -r 's/\"//g'|sed -r 's/VERSION=//g')

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

# GET LASTEST VERSIONS
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
    GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    OUTPUT=$(${GCP_SSH} --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get cm version -n '$NAMESPACE' -o json --kubeconfig="helpr/'"$KUBECONFIG"'";'| jq '.data')
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

# GET POD LOGS
get_pod_logs(){
  local OPTIND
  local ONSITE_ENV=false

  mkdir -p output/logs

  while getopts ":k:n:p:o" options; do
    case "${options}" in
      k)
         KUBECONFIG=${OPTARG};;
      n)
         NAMESPACE=${OPTARG};;
      o)
         ONSITE_ENV=true;;
      p)
         POD_SEARCH_STRING=${OPTARG};;
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

  if [[ -z "$KUBECONFIG" || -z "$NAMESPACE" || -z "$POD_SEARCH_STRING" ]]
  then
    echo -e "Error: helpr get-versions - please provide correct flags\n"
    echo -e "helpr get-versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://fake.website.com\n\nget-versions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment."
    exit 1
  fi

  if [ "$ONSITE_ENV" = true ]
  then
    GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    POD_OUTPUT=$(${GCP_SSH} --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get pods -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'";'| tail -n +2 | grep $POD_SEARCH_STRING)
  else
    POD_OUTPUT=$(kubectl get pods -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG | tail -n +2 | grep $POD_SEARCH_STRING)
  fi

  echo -e "$POD_OUTPUT\n"
  POD_OUTPUT=$(echo "$POD_OUTPUT" | grep -v Pending | grep -v Failed | awk '{print $1}')

  while IFS= read -r line ;
  do
    echo -e "Collecting Logs for" $line" ..."

    if [ "$ONSITE_ENV" = true ]
    then
      GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
      KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
      OUTPUT=$(${GCP_SSH} --ssh-flag='-qn' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl logs '"$line"' -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'";')
    else
      OUTPUT=$(kubectl logs $line -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG);
    fi
    
    if [ $? -eq 0 ]; then
      echo "$OUTPUT" > "output/logs/"$line".log"
      echo -e "Log stored in output/logs/"$line".log"
    fi
    echo ""
  done <<< "$POD_OUTPUT"
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
  get-logs)
    get_pod_logs "${@:2}" ;;
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

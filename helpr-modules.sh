#!/bin/bash

VERSION="v1.5"
DETAILS="> CHANGELOG:\n>> 'get-env-error' added\n\n> KNOWN ISSUES:\n>> Onsite operations are sometime stuck - Need to press enter"

version(){
  echo -e "$VERSION"
}

# HELP FUNCTION FOR GUIDE
banner() {
  #echo "test"
  echo -e "██   ██ ███████ ██      ██████  ██████  \n██   ██ ██      ██      ██   ██ ██   ██ \n███████ █████   ██      ██████  ██████  \n██   ██ ██      ██      ██      ██   ██ \n██   ██ ███████ ███████ ██      ██   ██ $VERSION\n                         --- BY RUDRADEV PAL\n"
}

help() {
  banner
  echo -e "Helpr Guide:\n\nhelpr version fetch current installed helpr version.\n\nhelpr update-check Checks if newer helpr version is available to install.\n\nhelpr update Update the current helpr version to latest [Internet Required].\n\nhelpr init Initilize helpr. Checks for all dependencies and installs if not present [Internet Required]. For the first use it is recommanded to run this command.\n\nhelpr get-versions fetchs current versions of deployed products from an environment.\n\nhelpr get-logs fetchs logs of deployed kubernets PODs from an environment matched by a string. It will fetch logs for all the matched PODs.\n\nget-logs usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment.\n  -p        Specify the string to match with POD name.\n  -o        (Optional) Specify this flag if it's on-site environment.\n\nhelpr get-versions fetchs current versions of deployed products from an environment.\n\nget-versions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment.\n  -o        (Optional) Specify this flag if it's on-site environment.\n  -f        (Optional) Specify this flag if it's you want to see all deployed versions.\n  -r        (Optional) Specify this flag if it's you want to see all deployed versions in raw format.\n\nhelpr get-env-error checks for any error in a deployed environment (Scale-Down issues, POD issues, Error logs). It will also fetch logs for all the error PODs.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://github.com/rudradevpal/helpr/blob/main/README.md\n\nget-env-error usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment.\n  -s        (Optional) Specify the string to search (for example app name).\n  -o        (Optional) Specify this flag if it's on-site environment.\n\nFind more information at: https://github.com/rudradevpal/helpr/blob/main/README.md" 1>&2
}

init(){
  local STATUS
  
  echo "Checking if GCloud SDK Installed..."
  STATUS=$(gcloud --version &> /dev/null;echo $?)
  if [[ $STATUS -ne 0 ]]
  then
    echo -e "\tNO"
    echo -e "\tInstalling GCloud SDK..."
    STATUS=$(sudo apt-get install -y apt-transport-https ca-certificates gnupg jq &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR:error installing dependencies"
      exit 1
    fi

    STATUS=$(echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error adding source list"
      exit 1
    fi

    STATUS=$(curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error gpg check"
      exit 1
    fi

    STATUS=$(sudo apt-get update &> /dev/null && sudo apt-get install -y google-cloud-cli &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error installing SDK"
      exit 1
    fi

    echo -e "\tOK"
  else
    echo "OK"
  fi
  
  echo ""

  echo "Checking if kubectl Installed..."
  STATUS=$(kubectl version --client=true &> /dev/null;echo $?)
  if [[ $STATUS -ne 0 ]]
  then
    echo -e "\tNO"
    echo -e "\tInstalling kubectl..."
    STATUS=$(sudo apt-get install -y apt-transport-https ca-certificates curl &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR:error installing dependencies"
      exit 1
    fi

    STATUS=$(sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error gpg check"
      exit 1
    fi

    STATUS=$(echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error adding source list"
      exit 1
    fi

    STATUS=$(sudo apt-get update &> /dev/null && sudo apt-get install -y kubectl &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error installing kubectl"
      exit 1
    fi

    echo -e "\tOK"
  else
    echo "OK"
  fi
  
  echo ""

  echo "Checking if NumPy Installed..."
  STATUS=$(python -c "import numpy; print(numpy.version.version)" &> /dev/null || python3 -c "import numpy; print(numpy.version.version)" &> /dev/null;echo $?)
  if [[ $STATUS -ne 0 ]]
  then
    echo -e "\tNO"
    echo -e "\tInstalling NumPy..."
    TMP=$(gcloud info --format="value(basic.python_location)")
    STATUS=$(${TMP} -m pip install numpy &> /dev/null;echo $?)
    if [[ $STATUS -ne 0 ]]
    then
      echo -e "\tERROR: error installing numpy"
      exit 1
    fi

    echo -e "\tOK"
  else
    echo "OK"
  fi
  
  echo ""

  echo "Checking if GCloud Project is Active..."
  GCP_PROJECT=$(jq '.gcp_project' config.json | tr -d '[],"')
  STATUS=$(gcloud config configurations list|grep "$GCP_PROJECT"|awk '{print $2}')
  if [[ "$STATUS" = "True" ]]
  then
    echo "OK"
  else
    echo "ERROR: Run 'gcloud init --no-browser' from bash and re-run 'helpr init' For more help visit https://cloud.google.com/sdk/gcloud/reference/init"
  fi

  echo ""

  echo "Creating directory stracture..."
  STATUS=$(mkdir -p kubeconfig/{local,onsite} &> /dev/null;echo $?)
  if [[ $STATUS -ne 0 ]]
  then
    echo "ERROR"
    exit 1
  else
    echo "OK"
  fi
  
  echo -e "\nPut local & On-Site kubeconfigs in respective directories under kubeconfig/\n\nPut 'config.json' under root directory of helpr"
}

update-check(){
  local SHORT=false
  local OPTIND
  while getopts ":s" options; do
    case "${options}" in
      s)
         SHORT=true;;
      :)
         echo -e "Error\n"
         echo -e "For full guide run helpr help"
         exit 1;;
      *)
         echo -e "Error\n"
         echo -e "For full guide run helpr help"
         exit 1;;
    esac
  done

  REMOTE_VERSION=$(curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/rudradevpal/helpr/main/helpr-modules.sh |grep VERSION= |head -n 1| sed -r 's/\"//g'|sed -r 's/VERSION=//g')
  if [ "$SHORT" = false ]
  then
    REMOTE_DETAILS=$(curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/rudradevpal/helpr/main/helpr-modules.sh |grep DETAILS= |head -n 1| sed -r 's/\"//g'|sed -r 's/DETAILS=//g')
    if [[ ! -z "$REMOTE_VERSION" && "$REMOTE_VERSION" != "$VERSION" ]]
    then
      echo -e "Update available: $REMOTE_VERSION\n$REMOTE_DETAILS"
    else
      echo "Helpr is up to date"
    fi
  else
    if [[ ! -z "$REMOTE_VERSION" && "$REMOTE_VERSION" != "$VERSION" ]]
    then
      echo -e "Update available: $REMOTE_VERSION"
    else
      echo "Helpr is up to date"
    fi
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
  local FULL_OUTPUT=false
  local RAW_OUTPUT=false
  local ONSITE_ENV=false
  local ERR_MSG="Error: helpr get-versions - please provide correct flags\n\nhelpr get-versions fetchs current versions of deployed products from an environment.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://github.com/rudradevpal/helpr/blob/main/README.md\n\nget-versions usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment.\n  -o        (Optional) Specify this flag if it's on-site environment.\n  -f        (Optional) Specify this flag if it's you want to see all deployed versions.\n  -r        (Optional) Specify this flag if it's you want to see all deployed versions in raw format."
  while getopts ":k:n:ofr" options; do
    case "${options}" in
      k)
         KUBECONFIG=${OPTARG};;
      n)
         NAMESPACE=${OPTARG};;
      o)
         ONSITE_ENV=true;;
      f)
         FULL_OUTPUT=true;;
      r)
         RAW_OUTPUT=true;;
      :)
         echo -e "$ERR_MSG"
         exit 1;;
      *)
         echo -e "$ERR_MSG"
         exit 1;;
    esac
  done

  if [[ -z "$KUBECONFIG" || -z "$NAMESPACE" ]]
  then
    echo -e "$ERR_MSG"
    exit 1
  fi
  ARTIFACTS=($(jq '.artifacts|keys' config.json | tr -d '[],"'))
  if [ "$ONSITE_ENV" = true ]
  then
    GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    OUTPUT=$(${GCP_SSH} --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get cm version -n '$NAMESPACE' -o json --kubeconfig="helpr/'"$KUBECONFIG"'"| jq ".data" | tail -n +2 | head -n -1 > helpr/output; cat helpr/output; exit 0')
  else
    OUTPUT=$(kubectl get cm version -n $NAMESPACE -o json --kubeconfig="kubeconfig/local/"$KUBECONFIG | jq '.data' | tail -n +2 | head -n -1;)
  fi
  if [ "$RAW_OUTPUT" = true ]
  then
    echo ">> VERSIONS (RAW):"
    while IFS= read -r line ;
    do
      RAW_VERSION=$(echo "$line"| sed -r 's/\"//g'|sed -r 's/,//g')
      if [[ ! -z "$RAW_VERSION" ]]
      then
        echo $RAW_VERSION
      fi
    done <<< "$OUTPUT"
  else
    if [ "$FULL_OUTPUT" = true ]
    then
      echo ">> VERSIONS (FULL):"
      for i in "${ARTIFACTS[@]}"
      do
        ARTIFACT_NAME=$(jq '.artifacts|."'$i'"' config.json| sed -r 's/\"//g')
        VERSION=$(echo "$OUTPUT"|grep "$i.")

        while IFS= read -r line ;
        do
          THIS_VERSION=$(echo "$line"| awk -F': ' '{print $2}'| sed -r 's/\"//g'|sed -r 's/,//g')
          if [[ ! -z "$THIS_VERSION" ]]
          then
            echo $ARTIFACT_NAME:$THIS_VERSION
          fi
        done <<< "$VERSION"
      done
    else
      echo ">> VERSIONS (LATEST):"
      for i in "${ARTIFACTS[@]}"
      do
        ARTIFACT_NAME=$(jq '.artifacts|."'$i'"' config.json| sed -r 's/\"//g')
        if [[ "$i" == *"datafix"* ]]
        then
          MULTI_OUTPUT=$(echo "$OUTPUT"|grep "$i.")
          while IFS= read -r line ;
          do
            VERSION=$(echo "$line"| awk -F': ' '{print $2}'| sed -r 's/\"//g'|sed -r 's/,//g')
            if [[ ! -z "$VERSION" ]]
            then
              echo $ARTIFACT_NAME:$VERSION
            fi
          done <<< "$MULTI_OUTPUT"
        else
          VERSION=$(echo "$OUTPUT"|grep "$i."| tail -1| awk -F': ' '{print $2}'| sed -r 's/\"//g'|sed -r 's/,//g')
          if [[ ! -z "$VERSION" ]]
          then
            echo $ARTIFACT_NAME:$VERSION
          fi
        fi
      done
    fi
  fi
}

# GET POD LOGS
get_pod_logs(){
  local OPTIND
  local ONSITE_ENV=false
  local ERR_MSG="Error: helpr get-logs - please provide correct flags\n\nhelpr get-logs fetchs logs of deployed kubernets PODs from an environment matched by a string. It will fetch logs for all the matched PODs.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://github.com/rudradevpal/helpr/blob/main/README.md\n\nget-logs usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment.\n  -p        Specify the string to match with POD name.\n  -o        (Optional) Specify this flag if it's on-site environment."

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
         echo -e "$ERR_MSG"
         exit 1;;
      *)
         echo -e "$ERR_MSG"
         exit 1;;
    esac
  done

  if [[ -z "$KUBECONFIG" || -z "$NAMESPACE" || -z "$POD_SEARCH_STRING" ]]
  then
    echo -e "$ERR_MSG"
    exit 1
  fi

  if [ "$ONSITE_ENV" = true ]
  then
    GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    POD_OUTPUT=$(${GCP_SSH} --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get pods -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'"; exit 0'| tail -n +2 | grep $POD_SEARCH_STRING)
  else
    POD_OUTPUT=$(kubectl get pods -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG | tail -n +2 | grep $POD_SEARCH_STRING)
  fi

  echo -e "$POD_OUTPUT\n"
  POD_OUTPUT=$(echo "$POD_OUTPUT" | grep -v Pending | grep -v Failed | awk '{print $1}')

  while IFS= read -r line ;
  do
    echo -e ">> Collecting Logs for" $line" ..."

    if [ "$ONSITE_ENV" = true ]
    then
      GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
      KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
      OUTPUT=$(${GCP_SSH} --ssh-flag='-qn' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl logs '"$line"' -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'"; exit 0')
    else
      OUTPUT=$(kubectl logs $line -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG);
    fi
    
    if [ $? -eq 0 ]; then
      echo "$OUTPUT" > "output/logs/"$line".log"
      echo -e ">>>> Log stored in output/logs/"$line".log"
    fi
    echo ""
  done <<< "$POD_OUTPUT"
}

# CHECK ENV ERROR
get_env_errors(){
  local OPTIND
  local SEARCH_STRING=""
  local ONSITE_ENV=false
  local POD_NAME=""
  local POD_STATUS=""
  local POD_READY=""
  local ERR=""
  local ERR_MSG="Error: helpr get-env-error - please provide correct flags\n\nhelpr get-env-error checks for any error in a deployed environment (Scale-Down issues, POD issues, Error logs). It will also fetch logs for all the error PODs.\n\n For more operations of helpr run\n     helpr help\n\n Find more information at: https://github.com/rudradevpal/helpr/blob/main/README.md\n\nget-env-error usage:\n  -k        Specify the name of kubeconfig file of the target environment. To get list of all kubeconfigs run 'helpr get-kubeconfigs'.\n  -n        Specify the namespace of the target environment.\n  -s        (Optional) Specify the string to search (for example app name).\n  -o        (Optional) Specify this flag if it's on-site environment."

  mkdir -p output/logs

  while getopts ":k:n:s:o" options; do
    case "${options}" in
      k)
         KUBECONFIG=${OPTARG};;
      n)
         NAMESPACE=${OPTARG};;
      o)
         ONSITE_ENV=true;;
      s)
         SEARCH_STRING=${OPTARG};;
      :)
         echo -e "$ERR_MSG"
         exit 1;;
      *)
         echo -e "$ERR_MSG"
         exit 1;;
    esac
  done

  if [[ -z "$KUBECONFIG" || -z "$NAMESPACE" ]]
  then
    echo -e "$ERR_MSG"
    exit 1
  fi

  if [ "$ONSITE_ENV" = true ]
  then
    GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    DEPLOY_OUTPUT=$(${GCP_SSH} --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get deploy -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'"; exit 0'| tail -n +2 | grep "$SEARCH_STRING")
  else
    DEPLOY_OUTPUT=$(kubectl get deploy -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG | tail -n +2 | grep "$SEARCH_STRING")
  fi

  if [ "$ONSITE_ENV" = true ]
  then
    GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
    KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
    POD_OUTPUT=$(${GCP_SSH} --ssh-flag='-q' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get pods -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'"; exit 0'| tail -n +2 | grep "$SEARCH_STRING")
  else
    POD_OUTPUT=$(kubectl get pods -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG | tail -n +2 | grep "$SEARCH_STRING")
  fi

  if [ "$POD_OUTPUT" == "No resources found in $NAMESPACE namespace." ]
  then
    POD_OUTPUT=""
  fi

  if [ "$DEPLOY_OUTPUT" == "No resources found in $NAMESPACE namespace." ]
  then
    DEPLOY_OUTPUT=""
  fi

  TMP=""
  while IFS= read -r line ;
  do
    DESIRED=$(echo $line| awk '{print $2}'| awk -F'/' '{print $2}')
    CURRENT=$(echo $line| awk '{print $2}'| awk -F'/' '{print $1}')
    if [ "$CURRENT" != "$DESIRED" ]
    then
      TMP="$TMP"$"$line"'\n'
    fi
  done <<< "$POD_OUTPUT"
  POD_OUTPUT=$(echo -e "$TMP")

  DEPLOY_OUTPUT=$(echo "$DEPLOY_OUTPUT" | grep 0/0)

  if [ ! -z "$DEPLOY_OUTPUT" ]
  then
    echo -e "> Below Deployments were scaled-down\n$DEPLOY_OUTPUT\n"
    if [ ! -z "$POD_OUTPUT" ]
    then
      echo -e "> Below PODs having issues\n$POD_OUTPUT\n"
    fi
  else
    if [ ! -z "$POD_OUTPUT" ]
    then
      echo -e "> Below PODs having issues\n$POD_OUTPUT\n"
    else
      echo -e "> No issues found in the environment $NAMESPACE"
      exit 0
    fi
  fi

  while IFS= read -r line ;
  do
    ERR=""
    POD_NAME=$(echo "$line"|awk '{print $1}')
    POD_STATUS=$(echo "$line"|awk '{print $3}')
    POD_READY=$(echo "$line"|awk '{print $2}')

    echo -e ">> Checking error for" $POD_NAME" ..."
    if [[ -z "$ERR" && "$POD_STATUS" = "ImagePullBackOff" ]]
    then
      if [ "$ONSITE_ENV" = true ]
      then
        GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
        KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
        ERR=$(${GCP_SSH} --ssh-flag='-qn' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get pod '"$POD_NAME"' -n '$NAMESPACE' -o json --kubeconfig="helpr/'"$KUBECONFIG"'"|jq ".status|.containerStatuses|.[]|.state|.waiting|.message"; exit 0' | tr -d '[],"')
      else
        ERR=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o json --kubeconfig="kubeconfig/local/"$KUBECONFIG|jq '.status|.containerStatuses|.[]|.state|.waiting|.message' | tr -d '[],"')
      fi
    elif [[ -z "$ERR" && "$POD_STATUS" = "Pending" ]]
    then
      if [ "$ONSITE_ENV" = true ]
      then
        GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
        KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
        ERR=$(${GCP_SSH} --ssh-flag='-qn' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl get pod '"$POD_NAME"' -n '$NAMESPACE' -o json --kubeconfig="helpr/'"$KUBECONFIG"'"|jq ".status|.conditions|.[]|.message";  exit 0' | tr -d '[],"')
      else
        ERR=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o json --kubeconfig="kubeconfig/local/"$KUBECONFIG|jq '.status|.conditions|.[]|.message' | tr -d '[],"')
      fi
    elif [[ -z "$ERR" && "$POD_STATUS" = "Completed" ]]
    then
      ERR="No error. POD is in completed state."
    elif [[ -z "$ERR" && "$POD_STATUS" = "Running" || "$POD_STATUS" = "CrashLoopBackOff" ]]
    then
      if [ "$ONSITE_ENV" = true ]
      then
        GCP_SSH=$(jq '.gcp_vm_ssh_command' config.json | tr -d '[],"')
        KUBECONFIG_CONTENT=$(cat "kubeconfig/onsite/"$KUBECONFIG)
        OUTPUT=$(${GCP_SSH} --ssh-flag='-qn' --command 'mkdir -p helpr; echo "'"$KUBECONFIG_CONTENT"'" > helpr/'$KUBECONFIG'; kubectl logs '"$POD_NAME"' -n '$NAMESPACE' --kubeconfig="helpr/'"$KUBECONFIG"'"; exit 0')
      else
        OUTPUT=$(kubectl logs "$POD_NAME" -n $NAMESPACE --kubeconfig="kubeconfig/local/"$KUBECONFIG);
      fi

      if [[ $? -eq 0 && ! -z "$OUTPUT" ]]
      then
        echo "$OUTPUT" > "output/logs/"$POD_NAME".log"
        echo -e ">>>> Full Log stored in output/logs/"$POD_NAME".log"
      fi

      ERR=$(echo "$OUTPUT" | grep error | tail -10)
      if [ -z "$ERR" ]
      then
        ERR="Did find ay error in the log. Please refer full log."
      fi
    fi
    echo -e ">>>> ERROR (Max last 10 Errors):"
    echo "$ERR"
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
         echo -e "For full guide run helpr help"
         exit 1;;
    esac
  done
  echo $KUBECONFIG-$NAMESPACE-$TEST
}


# MAIN SSWITCH CASE
case "$1" in
  init)
    init;;
  get-kubeconfigs)
    get_kubeconfigs;;
  get-versions)
    get_latest_versions "${@:2}" ;;
  get-logs)
    get_pod_logs "${@:2}" ;;
  get-env-error)
    get_env_errors "${@:2}" ;;
  version)
    version;;
  update-check)
    update-check "${@:2}";;
  help)
    help;;
  *)
    echo -e "Error: helpr requires an operation.\n"
    echo -e "For full guide run helpr help"
    exit 1;;
esac

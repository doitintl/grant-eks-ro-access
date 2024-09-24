
#!/bin/bash -u

set -e


case "$AWS_EXECUTION_ENV" in
  CloudShell) echo "This script is running in AWS CloudShell";;
  *)
    echo " This script is not running in AWS CloudShell" 1>&2
    exit 1
    ;;
esac


prepare_execution(){

  # install eksctl if not present
  echo "checking eksctl is installed"
  if command -v eksctl &> /dev/null
  then
      echo "eksctl is installed at version `eksctl version`"
  else
      echo "installing eksctl"
      curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
      sudo mv /tmp/eksctl /usr/local/bin
      echo "eksctl is installed at version `eksctl version`"
  fi

  repo_url="https://github.com/doitintl/grant-eks-ro-access.git"
  repo_dir="grant-eks-ro-access"

  # clone the repositoty
  if [ ! -d "$repo_dir" ]; then
    git clone "$repo_url" "$repo_dir"
  else
    echo "Repository already exists at $repo_dir"
  fi
  cd $repo_dir


  # gather info: cluster, region, account
  account=`aws sts get-caller-identity --query Account --output text`
  echo "Current account is : $account"
  region=`echo $AWS_REGION`
  echo "Current region is : $region"

  case $(aws eks list-clusters | jq '.clusters | length') in
    0) echo "You have no cluster in this account/region"; exit 0;;
    *)
      echo -e "\ncurrently you have these clisters:\n"
      aws eks list-clusters | jq '.clusters[]' -r
      echo -e "\n"
      read -p "which cluster do you want to provide access to ?: " cluster
  ;;
  esac
  export cluster=$cluster

  echo "Checking Cluster..."
  testClusterName $region $cluster

  # check endpoints
  vpc_conf=`aws eks describe-cluster --name $cluster --output json | jq '.cluster.resourcesVpcConfig' -r`
  export endpointPublicAccess=`echo $vpc_conf | jq '.endpointPublicAccess' -r`
  echo "endpointPublicAccess set to  : $endpointPublicAccess"
  export endpointPrivateAccess=`echo $vpc_conf | jq '.endpointPrivateAccess' -r`
  echo "endpointPrivateAccess set to  : $endpointPrivateAccess"
  export publicAccessCidrs=`echo $vpc_conf | jq '.publicAccessCidrs' -r`
  echo "publicAccessCidrs set to  : $publicAccessCidrs"


  # configure access to k8s cluster
  echo -e "\nSetting kubernetes configuration to access to the cluster and updating the current-context to use it"
  aws eks update-kubeconfig --name $cluster

  # check access to k8s cluster
  echo -e "\nChecking access to the cluster with kubectl"
  set +e
  kubectl  --request-timeout=2 get nodes > /dev/null
  if [ $? -eq 0 ]; then
      echo -e "Connection establised (kubectl get nodes command executed successfully)"
      set -e
  else
      echo -e "Error: impossible to communicate with the cluster (kubectl get nodes command failed)\n
      Please verify connectivity or access configuration.\n" >&2
      exit 1
  fi

}



testClusterName(){

    region=$1
    cluster_name=$2

    if aws eks describe-cluster  --region ${region}  --name ${cluster_name} > /dev/null 2>&1; then
      echo "Cluster Name: $cluster_name"
    else
        echo "impossible to find the cluster $cluster_name" 2>&1
        exit 1
    fi
}


grant(){

  echo -e "\nGranting permissions to the cluster : $cluster \n"
  ./grant-ro-accesses.sh --grant ${region}  ${cluster} arn:aws:iam::$account:role/DoiT-Support-Gateway

}


revoke(){

  echo -e "\nRevoking permissions to the cluster : $cluster \n"
  ./grant-ro-accesses.sh --revoke ${region}  ${cluster} arn:aws:iam::$account:role/DoiT-Support-Gateway

}



message="
Usage: ./execute_on_cloudshell.sh
[--grant ]
[--revoke ]
[--help]

\n\n
The command let to grant or revoke EKS read-only access to an AWS IAM entity.\n
Commands:\n
--grant: grant to Doit read-only permissions for the EKS cluster you choose interactively during the execution \n
--revoke: revoke to Doit read-only permissions for the EKS cluster you choose interactively during the execution \n
--help: show this message


"

while [ $# -gt 0 ] ; do
  case $1 in
    --grant) prepare_execution; grant; exit 0  ;;
    --revoke) prepare_execution; revoke; exit 0  ;;
    * )
     echo "Invalid Option: -$1" 1>&2
     echo -e $message
     exit 1
     ;;
  esac
  shift
done

echo -e $message

exit 0

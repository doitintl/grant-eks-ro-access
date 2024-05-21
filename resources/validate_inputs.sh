
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


validateRegion(){

    region=$1
    if aws ec2 describe-regions --output text --query 'Regions[].RegionName' | grep -w "$region" > /dev/null  2>&1; then
      echo "AWS region: $region"
    else
      echo "Invalid AWS region: $region" 1>&2
      exit 1
    fi
}


verifyInputs(){

    echo "\nverifying inputs ....."
    # todo: validate inputs
    echo "connecting to account number $(aws sts get-caller-identity |jq .Account -r)"

    case $# in
    4)
        validateRegion $2
        testClusterName $2 $3
        # validateTargetARN $4

        export region=$2
        export cluster_name=$3
        export role_arn=$4

        # check access to the cluster
        if aws eks describe-cluster  --region ${region}  --name ${cluster_name} > /dev/null; then
            echo "connection to the cluster ok"
        else
            echo "impossible to connect to the cluster: please check inputs (region and cluster name) or your permissions to AWS"
        fi

        echo "using region set to $region"
        echo "using cluster_name set to $cluster_name"
        echo "using role_arn set to $role_arn"

    ;;
    * )
        echo "Invalid inputs: provided inputs are $@" 1>&2
        exit 1
     ;;
    esac
}

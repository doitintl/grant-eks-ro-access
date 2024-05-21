
#!/bin/bash

source ./resources/verify_requirements.sh
source ./resources/validate_inputs.sh


updateConfigMap(){

    echo "\nupdating aws-auth ConfigMap ....."

    # backup aws-auth configmap
    echo "backup of the aws-config ConfigMap made in aws-config_history.yaml"
    kubectl get configmaps -n kube-system aws-auth -o yaml >> aws-config_history.yaml
    echo "---" >> aws-config_history.yaml

    echo "update aws-auth configmap ....."
    # this is to have an idempotent script
    eksctl delete iamidentitymapping  --cluster ${cluster_name}  --region=${region}  --arn ${role_arn}  2>/dev/null
    eksctl create iamidentitymapping --cluster ${cluster_name} --region=${region} \
        --arn ${role_arn} --username user --group doit:viewers \
        --no-duplicate-arns
}


createAccessEntry(){

    # https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
    echo "\ncreating access entries ........."

    echo "if present, I'll delete before"
    aws eks delete-access-entry --region ${region} --cluster-name ${cluster_name} --principal-arn ${role_arn} &> /dev/null

    echo "creation..."
    aws eks create-access-entry  --region ${region}  --cluster-name ${cluster_name} \
    --principal-arn ${role_arn} --type STANDARD --kubernetes-groups doit:viewers > /dev/null
    aws eks associate-access-policy  --region ${region}  --cluster-name ${cluster_name} \
        --principal-arn ${role_arn} \
        --access-scope type=cluster --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy > /dev/null
    echo "Done"

    echo "Now you have the following access entries on the cluster $cluster_name"
    aws eks list-access-entries --cluster-name ${cluster_name}
}

deleteAccessEntry(){

    echo "\ndeleting access entries ........."

    # TODO: check before?
    # result=$(aws eks list-access-entries --cluster-name ${cluster_name}  --output json | jq --arg arn "$role_arn" -r '.accessEntries[] | select(. == $arn)')
    # echo $result
    # if [ -n "$result" ]; then
    #   echo "The ARN $arn_to_filter was found."
    # else
    #   echo "The ARN $arn_to_filter was not found."
    # fi

    echo "if present, I'll delete it"
    aws eks delete-access-entry --region ${region} --cluster-name ${cluster_name} --principal-arn ${role_arn} 2>&1 > /dev/null
    echo "Done"

    echo "Now you have the following access entries on the cluster $cluster_name"
    aws eks list-access-entries --cluster-name ${cluster_name}

}



checkAuthenticationMode(){

    echo "\ncheck authenticationMode ........."
    export authenticationMode=$(aws eks describe-cluster  --region=${region}  --name ${cluster_name} | jq '.cluster.accessConfig.authenticationMode' -r)
    echo "authenticationMode is set to $authenticationMode"

}

grant(){

    # create a k8s doit group
    echo "creating a doit group ....."
    kubectl apply -f resources/k8s_objects.yaml

    checkAuthenticationMode

    case $authenticationMode in
    CONFIG_MAP) updateConfigMap; exit 0  ;;
    API) createAccessEntry; exit 0  ;;
    * )
    echo "Invalid Option: -$1" 1>&2
    exit 1
    ;;
    esac

}



revoke(){

    set -e # any arror will block the execution

    checkAuthenticationMode

    case $authenticationMode in
    CONFIG_MAP) TODO; exit 0  ;;
    API) deleteAccessEntry; exit 0  ;;
    * )
    echo "Invalid Option: -$1" 1>&2
    exit 1
    ;;
    esac

    echo "deleting the doit group ....."
    kubectl apply -f resources/k8s_objects.yaml


}





message="Usage: ././grant-ro-accesses.sh
[--grant <region> <clusterName> <arn>]
[--revoke <region> <clusterName> <arn>]
[--verifyRequirements]
"

while [ $# -gt 0 ] ; do
  case $1 in
    --grant) verifyRequirements; verifyInputs $@; grant; exit 0  ;;
    --revoke) verifyRequirements; verifyInputs $@; revoke; echo "NOT COMPLETELY IMPLEMENTED"  1>&2;  exit 1  ;;
    --verifyRequirements) verifyRequirements; exit 0  ;;
    --help)  echo "$message" ; exit 0  ;;
    * )
     echo "Invalid Option: -$1" 1>&2
     echo $message
     exit 1
     ;;
  esac
  shift
done

echo $message

exit 0


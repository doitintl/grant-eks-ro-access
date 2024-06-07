#!/bin/bash -u

source ./resources/verify_requirements.sh
source ./resources/validate_inputs.sh


addRightsToConfigMap(){

    echo "\nupdating aws-auth ConfigMap to grant permissions....."
    echo "backup of the aws-config ConfigMap made in aws-config_history.yaml"
    kubectl get configmaps -n kube-system aws-auth -o yaml >> aws-config_history.yaml
    echo "---" >> aws-config_history.yaml
    echo "update aws-auth configmap ....."
    # this is to have an idempotent script (alternatively check if already exists)
    eksctl delete iamidentitymapping --cluster ${cluster_name}  --region=${region}  --arn ${role_arn}  2>/dev/null
    eksctl create iamidentitymapping --cluster ${cluster_name} --region=${region} \
        --arn ${role_arn} --username doit-ro-user --group doit:viewers \
        --no-duplicate-arns

}


removeRightsToConfigMap(){

    echo "\nupdating aws-auth ConfigMap to revoke permissions ....."
    echo "backup of the aws-config ConfigMap made in aws-config_history.yaml"
    kubectl get configmaps -n kube-system aws-auth -o yaml >> aws-config_history.yaml
    echo "---" >> aws-config_history.yaml
    echo "update aws-auth configmap ....."
    eksctl delete iamidentitymapping  --cluster ${cluster_name}  --region=${region}  --arn ${role_arn}

}


createAccessEntry(){

    # https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
    echo "\ncreating access entries ........."
    checkIfAccessEntryExists
    case "$accessEntrieAlreadyExists" in
        1)
            echo "The access entry alredy exists: nothing to do"
            ;;
        0)
            echo "The access entry doen't exist"
            echo "creation..."
            aws eks create-access-entry  --region ${region}  --cluster-name ${cluster_name} \
            --principal-arn ${role_arn} --type STANDARD --kubernetes-groups doit:viewers > /dev/null
            aws eks associate-access-policy  --region ${region}  --cluster-name ${cluster_name} \
                --principal-arn ${role_arn} \
                --access-scope type=cluster --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy > /dev/null
            echo "Done"
            ;;
    esac
    echo "Now you have the following access entries on the cluster $cluster_name"
    aws eks list-access-entries --cluster-name ${cluster_name} | jq '.accessEntries'
}


checkIfAccessEntryExists(){

    export accessEntrieAlreadyExists=0
    json_data=`aws eks list-access-entries --cluster-name ${cluster_name}  --output json`
    if echo "$json_data" | grep -q "$role_arn"; then
        echo "The access entry for '$role_arn' is present"
        export accessEntrieAlreadyExists=1
    else
        echo "The access entry for '$role_arn' is not present"
    fi
}


deleteAccessEntry(){

    echo "\ndeleting access entries ........."
    checkIfAccessEntryExists
    case "$accessEntrieAlreadyExists" in
        1)
            echo "deleting the access entry"
            aws eks delete-access-entry --region ${region} --cluster-name ${cluster_name} --principal-arn ${role_arn}
            ;;
        0)
            echo "The access entry doen't exist: nothing to do"
            ;;
    esac
    echo "Now you have the following access entries on the cluster $cluster_name"
    aws eks list-access-entries --cluster-name ${cluster_name} | jq '.accessEntries'

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
        CONFIG_MAP) addRightsToConfigMap; exit 0  ;;
        API) createAccessEntry; exit 0  ;;
        API_AND_CONFIG_MAP) createAccessEntry; exit 0  ;;
        # note (from https://aws.amazon.com/it/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/):
        # When API_AND_CONFIG_MAP is enabled, the cluster will source authenticated AWS IAM principals from both Amazon EKS access entry APIs and the aws-auth configMap, with priority given to the access entry API.
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
    CONFIG_MAP) removeRightsToConfigMap; exit 0  ;;
    API) deleteAccessEntry; exit 0  ;;
    API_AND_CONFIG_MAP) deleteAccessEntry; exit 0  ;;
    * )
        echo "Authentication mode invalid" 1>&2
        exit 1
    ;;
    esac

    echo "deleting the doit group ....."
    kubectl apply -f resources/k8s_objects.yaml


}





message="Usage: ./grant-ro-accesses.sh
[--grant <region> <clusterName> <arn>]
[--revoke <region> <clusterName> <arn>]
[--verifyRequirements]
[--help]

"

while [ $# -gt 0 ] ; do
  case $1 in
    --grant) verifyRequirements; verifyInputs $@; grant; exit 0  ;;
    --revoke) verifyRequirements; verifyInputs $@; revoke; exit 0  ;;
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


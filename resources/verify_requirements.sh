


# the function verify all the requirement needed by the bash script TODO
verifyRequirements() {

    echo "verify requirements ........."

    # Check if the current shell is Bash (this improve compability)
    if [ -z "$BASH_VERSION" ]; then
        echo "This script must be executed in a Bash shell."
        exit 1
    fi

    echo "checking if kubectl is installed"
    kubectl version  --client > /dev/null
    if [ $? -eq 0 ]; then
        echo "kubectl get nodes command executed successfully"
    else
        echo "Error: kubectl get nodes command failed." >&2
        exit 1
    fi

    echo "checking eksctl is installed"
    eksctl info > /dev/null
    if [ $? -eq 0 ]; then
        echo "eksctl is installed "
    else
        echo "Error: eksctl not installed" >&2
        exit 1
    fi


    echo "checking jq is installed"
    jq -V > /dev/null
    if [ $? -eq 0 ]; then
        echo "jq is installed "
    else
        echo "Error: jq not installed" >&2
        exit 1
    fi

    echo "checking aws cli is installed"
    aws --version > /dev/null
    if [ $? -eq 0 ]; then
        echo "aws is installed "
    else
        echo "Error: aws not installed" >&2
        exit 1
    fi

}

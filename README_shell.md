# Use on Schell


Here a single-line command that can be execute in your current Shell to grant or revoke EKS permissions to DoiT. This script will install eksctl if it does not exist, will configure your .kube/config file with the name of the cluster provided and will run the grant-ro-accesses.sh script to give permissions to the DoiT arn:aws:iam::$account:role/DoiT-Support-Gateway.


## Requirements
You can run this script from a shell where you have aws cli access with a user admin of the cluster and kubectl access to your cluster.
Please configure the environment variable $AWS_REGION with the AWS region where your cluster is located.

## Grant permissions
Here is the command to use:
```bash
wget --no-cache https://github.com/doitintl/grant-eks-ro-access/blob/feature/execute_on_shell/shell/execute_on_shell.sh -O execute_on_shell.sh && bash -i execute_on_shell.sh --grant
```

## Revoke permissions
Here is the command to use:
```bash
wget --no-cache https://github.com/doitintl/grant-eks-ro-access/blob/feature/execute_on_shell/shell/execute_on_shell.sh -O execute_on_shell.sh && bash -i execute_on_shell.sh --revoke
```

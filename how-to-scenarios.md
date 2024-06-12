# Use on CloudSchell


Here a single-line command that can be execute in CloudShell to grant or revoke EKS permissions to DoiT


## Requirements
You need to access to the AWS Console with the user admin of the cluster, in the same region.

## Grant permissions
Here is the command to use:
```bash
wget --no-cache https://raw.githubusercontent.com/doitintl/grant-eks-ro-access/main/cloudshell/execute_on_cloudshell.sh -o execute_on_cloudshell.sh && bash -i execute_on_cloudshell.sh --grant
```

## Revoke permissions
Here is the command to use:
```bash
wget --no-cache https://raw.githubusercontent.com/doitintl/grant-eks-ro-access/main/cloudshell/execute_on_cloudshell.sh  -o execute_on_cloudshell.sh && bash -i execute_on_cloudshell.sh --revoke
```
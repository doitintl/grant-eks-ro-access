# The problem with public endpoint

This how-to is useful in case you want to run the script "execute_on_cloudshell.sh" with EKS clusters not having public endpoint enabled.
In this case you can still execute the script by using "[AWS CloudShell in Amazon VPC](https://docs.aws.amazon.com/cloudshell/latest/userguide/using-cshell-in-vpc.html)": with this feature, a CloudShell environment can be create in the VPC where the private endpoint are available and accessible.



## How to create a CloudShell environment letting to access private endpoints

1. On the CloudShell console page, choose the + icon and then choose "Create VPC environment" from the dropdown menu
2. On the Create a VPC environment page, enter a name for your VPC environment in the Name box
3. From the Virtual private cloud (VPC) dropdown list, choose the VPC used by your cluster
4. From the Subnet dropdown list, choose the subnet used by your cluster
5. From the Security group dropdown list, choose the security group used by your cluster.
6. Click on the button "Create" to create your VPC environment.


Now you can execute the command:

```bash
wget --no-cache https://raw.githubusercontent.com/doitintl/grant-eks-ro-access/main/cloudshell/execute_on_cloudshell.sh -O execute_on_cloudshell.sh && bash -i execute_on_cloudshell.sh --grant
```

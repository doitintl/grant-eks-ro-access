# Grant read-only access to a EKS cluster

The script automates all the steps needed to grant read-only access to a EKS.
It also lets the to revoke the provided accesses.

## How To

### Requirements

Before executing the script you need to install:
- jq
- kubectl
- eksctl
- aws cli
And you need to have admin permissions to the cluster.
There requirements are tested by the script.


### Grant read-only accesses:

```bash
./grant-ro-accesses.sh --grant <region> <clusterName> <arn>
```

Inputs to provide:

- region: aws region where the cluster is
- clusterName: eks cluster name
- arn: IAM arn to provide accesses to

Example:

```bash
./grant-ro-accesses.sh --start eu-west-1 cluster_name arn:aws:iam::123456789000:user/programmatic/eks_user
```


### Revoke accesses:

TODO



## How does it work

This script leverage two EKS authentication methods providing permission to an AWS IAM entity:
- ConfigMap aws-auth: today deprecated but used by the majority of current clusters
- Access Entries: the recommended way


In both scenarios, a Cluster Role with read-only permissions is created and bound to a kubernetes group “doit-viewer”: the AWS IAM ARN will be added to this group, acquiring read-only permissions provided by the ClusterRole.
Based on the cluster configuration, this last step is made with ConfigMap aws-auth or Access Entries.

![Alt Text](./doc_resources/goal-of-the-script.svg)


### Flow process of the script

![Alt Text](./doc_resources/schema.svg)


## Features

The script:

- provides the ability to grant and remove permissions
- is robust: any prerequisite is tested
- is idempotent: you can run it any time and have the same result (feature ongoing)


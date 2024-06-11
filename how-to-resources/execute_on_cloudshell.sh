
#!/bin/bash -u
set -e


# install eksctl
echo "installing eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
echo "eksctl is installed at version `eksctl version`"


repo_url="https://github.com/doitintl/grant-eks-ro-access.git"
repo_dir="grant-eks-ro-access"

# clone the repositoty
if [ ! -d "$repo_dir" ]; then
  git clone "$repo_url" "$repo_dir"
else
  echo "Repository already exists at $repo_dir"
fi

cd $repo_dir

echo -e "\ncurrently you have these clister\n"
aws eks list-clusters | jq .clusters[] -r
read -p "\nwhich cluster do you want to provide access to ?: " cluster

echo "we are going to provide read-only accesses to the cluster: $cluster"

account=`aws sts get-caller-identity --query Account --output text`
echo "Current account is : $account"

region=`echo $AWS_REGION`
echo "Current region is : $region"

aws eks update-kubeconfig --name $cluster

./grant-ro-accesses.sh --grant ${region}  ${cluster} arn:aws:iam::$account:role/DoiT-Support-Gateway







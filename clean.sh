export HTTP_PROXY=http://jmix:jmix@54.215.128.225:8888
export HTTPS_PROXY=http://jmix:jmix@54.215.128.225:8888
terraform init -input=false
unset HTTP_PROXY
unset HTTPS_PROXY
terraform destroy --auto-approve -input=false

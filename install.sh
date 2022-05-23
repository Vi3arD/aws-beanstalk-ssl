export HTTP_PROXY=http://jmix:jmix@154.215.128.225:8888
export HTTPS_PROXY=http://jmix:jmix@154.215.128.225:8888
terraform init -input=false
unset HTTP_PROXY
unset HTTPS_PROXY
terraform apply --auto-approve -input=false -var="image=${CC_IMAGE_NAME}" -var="access_key_id=${AWS_ACCESS_KEY_ID}" -var="secret_access_key=${AWS_SECRET_ACCESS_KEY}"

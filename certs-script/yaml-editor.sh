BASE64_CERT=$(base64 -i ca.cert | tr -d '\n')
sed -i '' "s/\$(CERT_DATA)/$BASE64_CERT/" ../kubernetes-configs/regain-access.yaml

generate_kubedam_pub_key:
	kubeseal --fetch-cert \
	--controller-namespace=adm \
	--controller-name=sealed-secrets \
	> pub-cert.pem

## @param name: string 
## @param ns: string
## @param file: string -- File path
generate_secret_file:
	kubectl create secret generic $(name) -n $(ns) \
	--from-file=$(file) \
	--dry-run \
	-o json > $(file).json
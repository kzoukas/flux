seal:
	mkdir -p .secrets/generated

	kubectl create secret generic $(name) -n $(ns) \
	--from-file=$(file) \
	--dry-run \
	-o json > .secrets/generated/$(name).json

	kubeseal --format=yaml --cert=.secrets/cert.pem < .secrets/generated/$(name).json > .secrets/generated/$(name).yaml

	rm .secrets/generated/$(name).json
playbook:
	cd ansible && ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass && cd ..
	
kube-calibre:
	kubectl apply -f ./k3s/calibre-web.yml

kube-immich:
	kubectl apply -f ./k3s/immich-secret.yml
	kubectl apply -f ./k3s/immich-postgres.yml
	kubectl apply -f ./k3s/immich-redis.yml
	kubectl apply -f ./k3s/immich-server.yml
kube-pods:
	kubectl get pods -w


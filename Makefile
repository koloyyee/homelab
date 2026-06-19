playbook:
	cd ansible && ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass && cd ..
	

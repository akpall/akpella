config.json: config.yaml
	docker run --rm -i \
	  quay.io/coreos/butane:latest \
	  --strict \
	  --pretty \
	  < config.yaml > config.json

reset: config.json
	if ! [[ -f config.json && -s config.json ]]; then \
	  echo "No config.json" && \
	  exit 1; \
	fi; \

	ssh -o ControlMaster=auto -o ControlPath=/tmp/ssh_mux_%h_%p_%r -o ControlPersist=10m -fN akpella && \
	TEMPDIR=$$(ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r akpella "cd /tmp && mktemp -d") && \
	scp -o ControlPath=/tmp/ssh_mux_%h_%p_%r config.json akpella:$${TEMPDIR} && \
	ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r akpella \
	  sudo flatcar-reset \
	  --ignition-file $${TEMPDIR}/config.json \
	  --keep-machine-id \
	  --keep-paths '/etc/ssh/ssh_host_.*' /var/log && \
	ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r akpella \
	  sudo systemctl reboot && \
	ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r -O exit akpella;

update:
	VER=$$(curl -fsSL https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt | grep FLATCAR_VERSION= | cut -d = -f 2) && \
	echo $${VER} && \
	ssh akpella sudo flatcar-update -V $${VER} -A

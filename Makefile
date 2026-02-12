FILES := $(wildcard files/*)

default:
	$(MAKE) .generate-files-list
	$(MAKE) config.json
.PHONY: default

reset:
	$(MAKE) default
	$(MAKE) .reset
.PHONY: reset

.generate-files-list: $(FILES)
	if ! echo $(FILES) | diff -q .files-list - >/dev/null 2>&1; then \
	  echo $(FILES) > .files-list; \
	fi
.PHONY: .generate-files-list

config.json: config.yaml .files-list $(FILES)
	docker run --rm -i \
	  --volume ${PWD}:/pwd \
	  --workdir /pwd \
	  quay.io/coreos/butane:latest \
	  --strict \
	  --pretty \
	  --files-dir files \
	  < config.yaml > config.json

.reset: config.json
	-rm .reset
	ssh -o ControlMaster=auto -o ControlPath=/tmp/ssh_mux_%h_%p_%r -o ControlPersist=10s -fN akpella && \
	TEMPDIR=$$(ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r akpella "cd /tmp && mktemp -d") && \
	scp -o ControlPath=/tmp/ssh_mux_%h_%p_%r config.json akpella:$${TEMPDIR} && \
	ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r akpella \
	  sudo flatcar-reset \
	  --ignition-file $${TEMPDIR}/config.json \
	  --keep-machine-id \
	  --keep-paths '/etc/ssh/ssh_host_.*' \
	  --keep-paths '/opt/caddy/data' \
	  --keep-paths '/var/log' && \
	ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r akpella \
	  sudo systemctl reboot && \
	ssh -o ControlPath=/tmp/ssh_mux_%h_%p_%r -O exit akpella;
	touch .reset

update:
	VER=$$(curl -fsSL https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt | grep FLATCAR_VERSION= | cut -d = -f 2) && \
	echo $${VER} && \
	ssh akpella sudo flatcar-update -V $${VER} -A

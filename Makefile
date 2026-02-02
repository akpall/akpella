config.json: config.yaml
	docker run --rm -i \
	  quay.io/coreos/butane:latest \
	  --strict \
	  --pretty \
	  < config.yaml > config.json

reset: config.json
	if [ ! -f config.json ]; then \
	  echo "No config.json" && \
	  exit 1; \
	fi; \
	TEMPDIR=$$(ssh akpella "cd /tmp && mktemp -d") && \
	scp config.json akpella:$${TEMPDIR} && \
	ssh akpella sudo flatcar-reset \
	  --ignition-file $${TEMPDIR}/config.json \
	  --keep-machine-id \
	  --keep-paths '/etc/ssh/ssh_host_.*' /var/log && \
	ssh akpella sudo systemctl reboot

update:
	VER=$$(curl -fsSL https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt | grep FLATCAR_VERSION= | cut -d = -f 2) && \
	echo $${VER} && \
	ssh akpella sudo flatcar-update -V $${VER} -A

akpall-ignition.raw:
	curl -Os https://github.com/akpall/sysext-bakery/blob/akpella/akpall-ignition.raw
.PHONY: akpall-ignition.raw

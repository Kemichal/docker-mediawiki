#!/bin/bash

echo -e '{\n  "storage-driver": "overlay2"\n}' > /etc/docker/daemon.json
service docker restart

#!/bin/bash
Now=$(date +%F_%H-%M-%S)
zip -r "/pi-gen/deploy/$Now.zip" ./BINARY_FILES/ 
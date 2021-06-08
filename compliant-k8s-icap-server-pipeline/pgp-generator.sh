#!/bin/bash

cat >pipeline_key_config <<EOF
     %echo Generating a basic OpenPGP key
     %no-protection
     Key-Type: DSA
     Key-Length: 1024
     Subkey-Type: ELG-E
     Subkey-Length: 1024
     Name-Real: Jakub Krzywda
     Name-Email: jakub@elastisys.com
     Expire-Date: 0
     # Do a commit here, so that we can later print "done" :-)
     %commit
     %echo done
EOF

gpg --batch --generate-key pipeline_key_config

FP=$(gpg --fingerprint | sed -n 4p | tr -d '[:space:]')

cat >.sops.yaml <<EOF
creation_rules:
  - pgp: $FP
EOF
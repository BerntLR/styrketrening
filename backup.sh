#!/usr/bin/env bash
msg="${1:-auto backup}"
git add .
git commit -m "$msg"
git push

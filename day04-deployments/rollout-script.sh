#!/usr/bin/env bash
kubectl set image deployment/web-deploy nginx=nginx:1.28 --record
kubectl rollout status deployment/web-deploy

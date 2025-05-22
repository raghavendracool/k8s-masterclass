#!/usr/bin/env bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress ingress-nginx/ingress-nginx --namespace ingress --create-namespace

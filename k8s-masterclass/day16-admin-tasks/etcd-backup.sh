#!/usr/bin/env bash
ETCDCTL_API=3 etcdctl snapshot save etcd-$(date +%Y%m%d).db --endpoints=https://127.0.0.1:2379 \ 
  --cacert=/etc/kubernetes/pki/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key

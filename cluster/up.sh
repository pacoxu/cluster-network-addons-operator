#!/bin/bash
#
# Copyright 2018-2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

SCRIPTS_PATH="$(dirname "$(realpath "$0")")"
source ${SCRIPTS_PATH}/cluster.sh

cluster::install

$(cluster::path)/cluster-up/up.sh

if [[ "$KUBEVIRT_PROVIDER" =~ (ocp|okd)- ]]; then
    echo 'Remove components we do not need to save some resources'
    ./cluster/kubectl.sh delete ns openshift-monitoring --wait=false
    ./cluster/kubectl.sh delete ns openshift-marketplace --wait=false
    ./cluster/kubectl.sh delete ns openshift-cluster-samples-operator --wait=false
fi

if [[ "$KUBEVIRT_PROVIDER" =~ k8s- ]]; then
    echo 'Installing Open vSwitch and NetworkManager 1.34 on nodes'
    for node in $(./cluster/kubectl.sh get nodes --no-headers | awk '{print $1}'); do
        ./cluster/cli.sh ssh ${node} -- sudo dnf install -y centos-release-nfv-openvswitch
        ./cluster/cli.sh ssh ${node} -- sudo dnf install -y openvswitch2.16 libibverbs NetworkManager-1.34.0 NetworkManager-ovs-1.34.0
        ./cluster/cli.sh ssh ${node} -- sudo systemctl daemon-reload
        ./cluster/cli.sh ssh ${node} -- sudo systemctl enable --now openvswitch
        ./cluster/cli.sh ssh ${node} -- sudo systemctl restart openvswitch
        ./cluster/cli.sh ssh ${node} -- sudo systemctl restart NetworkManager
    done
fi

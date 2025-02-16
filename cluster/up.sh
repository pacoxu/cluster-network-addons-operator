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

export KUBEVIRT_DEPLOY_PROMETHEUS=true
export KUBEVIRT_DEPLOY_PROMETHEUS_ALERTMANAGER=true
export KUBEVIRT_DEPLOY_GRAFANA=true

cluster::install

$(cluster::path)/cluster-up/up.sh

if [[ "$KUBEVIRT_PROVIDER" =~ k8s- ]]; then
    echo 'Installing Open vSwitch'
    for node in $(./cluster/kubectl.sh get nodes --no-headers | awk '{print $1}'); do
        ./cluster/cli.sh ssh ${node} -- sudo dnf install -y centos-release-nfv-openvswitch
        ./cluster/cli.sh ssh ${node} -- sudo dnf install -y openvswitch2.16 libibverbs
        ./cluster/cli.sh ssh ${node} -- sudo systemctl daemon-reload
        ./cluster/cli.sh ssh ${node} -- sudo systemctl enable --now openvswitch
        ./cluster/cli.sh ssh ${node} -- sudo systemctl restart openvswitch
    done
fi

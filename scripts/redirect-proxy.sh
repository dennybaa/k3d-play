#!/bin/bash
set -e
: "${K3D_CLUSTER:?Must be set}"

k3d="${K3D_CLUSTER}"
CRCLI="$(which podman || :)"
CRCLI="${CRCLI:-$(which docker || :)}"

if [ -z "$CRCLI" ]; then
    >&2 echo "No docker or podman found!" && exit 1
fi

destroy="no"
rule() {
    local dport="$1" host="$2" port="$3" destroy="$4" exists=""

    RULE="OUTPUT -s 127.0.0.0/8 -d ${host} -p tcp -m tcp --dport $dport -j REDIRECT --to-ports ${port}"
    sudo -n true 2>/dev/null || { echo -e "\nRedirct localhost http(s) traffic into K8S. Runing iptables requires root..."; sudo -i true; }
    sudo -n iptables -t nat -C $RULE &>/dev/null && exists="yes" || exists="no"

    if [[ "$exists" == "no" ]] && [[ "$destroy" != "yes" ]] ; then
        sudo -n iptables -t nat -A $RULE
        echo "   ✔ added iptables rule to redirect traffic localhost:${dport} to ${host}:${port}"
    elif [[ "$exists" == "yes" ]] && [[ "$destroy" == "yes" ]]; then
        sudo -n iptables -t nat -D $RULE
        echo "   ✗ deleted iptables rule to redirect traffic localhost:${dport} to ${host}:${port}"
    fi
}

if [ "$1" = "destroy" ]; then destroy="yes"; fi
read port host  <<< $($CRCLI inspect k3d-${k3d}-serverlb --format '{{ $d := (index (index .NetworkSettings.Ports "80/tcp") 0) }}{{ $d.HostPort }} {{ $d.HostIP }}' 2>/dev/null)
rule 80 "${host:-localhost}" $port

read port host <<< $($CRCLI inspect k3d-${k3d}-serverlb --format '{{ $d := (index (index .NetworkSettings.Ports "443/tcp") 0) }}{{ $d.HostPort }} {{ $d.HostIP }}' 2>/dev/null)
rule 443 "${host:-localhost}" $port

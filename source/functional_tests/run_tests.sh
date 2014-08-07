#!/bin/bash

export VAGRANT_OPENSTACK_LOG=debug

export OS_KEYPAIR_NAME=vagrant-openstack
export OS_KEYPAIR_PRIVATE_KEY=keys/vagrant-openstack

export OS_SSH_TIMEOUT=600
export OS_SYNC_METHOD=none
export OS_SSH_SHELL=bash
export OS_SSH_USERNAME=
export OS_SERVER_NAME=
export OS_IMAGE=
export OS_FLOATING_IP=

ERROR_STATE=0

cat > /tmp/images_with_ssh_user <<EOL
ubuntu-12.04_x86_64_HWE;stack
ubuntu-14.04_x86_64_LVM;stack
debian7_x86_64_LVM;stack
centos65_x86_64_LVM;stack
EOL

#
# $1 - Log level
# $2 - Action (e.g. UP, SSH, DESTROY)
# $* - Text
#
function log() {
    [ $# -lt 3 ] && echo "Logger error..." >&2 && exit 1
    level=$1   ; shift
    action=$1  ; shift
    printf "$(date '+%Y-%m-%d %H:%M:%S') | %10s | %10s | %s\n" ${level} ${action} "$*" | tee -a test.log
}

#
# $1 - Action (e.g. UP, SSH, DESTROY)
# $* - Text
#
function logInfo() {
    action=$1
    shift
    log INFO ${action} $*
}

#
# $1 - Action (e.g. UP, SSH, DESTROY)
# $* - Text
#
function logError() {
    action=$1
    shift
    log ERROR ${action} $*
    ERROR_STATE=1
}

#
# $1 - Action (e.g. UP, SSH, DESTROY)
# $* - Text
#
function logSuccess() {
    action=$1
    shift
    log SUCCESS ${action} $*
}

runSingleTest() {

    testSummary="${OS_SERVER_NAME} - ${OS_IMAGE} - ${OS_SSH_USERNAME}"

    logInfo 'START' ${testSummary}

    bundle exec vagrant up --provider openstack 2>&1 | tee -a ${OS_SERVER_NAME}_up.log
    if [ ${PIPESTATUS[0]} -ne 0 ] ; then
        logError 'UP' ${testSummary}
    else
        logSuccess 'UP' ${testSummary}
        bundle exec vagrant ssh -c "cat /tmp/test_shell_provision" 2>&1 | tee -a ${OS_SERVER_NAME}_ssh.log
        if [ ${PIPESTATUS[0]} -ne 0 ] ; then
            logError 'SSH' ${testSummary}
        else
            logSuccess 'SSH' ${testSummary}
        fi
    fi

    bundle exec vagrant destroy 2>&1 | tee -a ${OS_SERVER_NAME}_destroy.log
    if [ ${PIPESTATUS[0]} -ne 0 ] ; then
        logError 'DESTROY' ${testSummary}
    else
        logSuccess 'DESTROY' ${testSummary}
    fi

    logInfo 'END' ${testSummary}

}

#
# $1 - Instance name prefix
# $2 - Floating IP tu use
#
function runAllTests() {
    name=${1}
    ip=${2}
    nbIteration=${3}
    i=1
    rm -f test.log ${name}_*.log
    touch test.log
    for (( n=1 ; n<=${nbIteration} ; n++ )) ; do
        nbTests=$(cat /tmp/images_with_ssh_user | wc -l)
        for (( i=1 ; i<=${nbTests} ; i++ )) ; do
            currentTest=$(cat /tmp/images_with_ssh_user | head -n ${i} | tail -n 1)
            export OS_SERVER_NAME="${name}_${n}_${i}"
            export OS_IMAGE=$(echo "${currentTest}" | cut -f1 -d";")
            export OS_FLOATING_IP="${ip}"
            export OS_SSH_USERNAME=$(echo "${currentTest}" | cut -f2 -d";")
            runSingleTest
        done
    done
}

runAllTests 'test' '185.39.216.103' 1

echo ''
echo '################################################################################################'
echo '# Report summary                                                                               #'
echo '################################################################################################'
echo ''
cat test.log
echo ''
echo '################################################################################################'
echo ''

exit ${ERROR_STATE}

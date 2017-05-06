#!/bin/bash

export SCRIPT_HOME=$(dirname $(readlink -f $0))

[[ `systemctl is-enabled firewalld` ]] && systemctl disable firewalld
[[ `systemctl is-active firewalld` ]] && systemctl stop firewalld
[[ `systemctl is-enabled NetworkManager` ]] && systemctl disable NetworkManager
[[ `systemctl is-active NetworkManager` ]] && systemctl stop NetworkManager
[[ `systemctl is-enabled network` ]] || systemctl enable network
[[ `systemctl is-active network` ]] || systemctl start network

# disable dns
sed -i 's/^#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd.service

# install packstack
rpm -qa centos-release-openstack-ocata > /dev/null || yum -y install centos-release-openstack-ocata
rpm -qa openstack-packstack > /dev/null || yum -y install openstack-packstack

# fix libvirtd
rpm -qa avahi > /dev/null || yum -y install avahi

# generate answer file
[[ -f $SCRIPT_HOME/my_answer_file ]] || packstack --gen-answer-file=$SCRIPT_HOME/my_answer_file

# fix packstack bug
# for more details see: https://review.openstack.org/#/c/440258/
sed -i 's/physnet1/extnet/' /usr/lib/python2.7/site-packages/packstack/plugins/neutron_350.py
\cp -r $SCRIPT_HOME/update/ironic.pp /usr/share/openstack-puppet/modules/packstack/manifests/nova/compute/ironic.pp
\cp -r $SCRIPT_HOME/update/sched_ironic.pp /usr/share/openstack-puppet/modules/packstack/manifests/nova/sched/ironic.pp
\cp -r $SCRIPT_HOME/update/controller.pp /usr/lib/python2.7/site-packages/packstack/puppet/templates/controller.pp

# set answer file
sed -i 's/CONFIG_IRONIC_INSTALL=n/CONFIG_IRONIC_INSTALL=y/' $SCRIPT_HOME/my_answer_file
sed -i 's/CONFIG_IRONIC_DB_PW=PW_PLACEHOLDER/CONFIG_IRONIC_DB_PW=ironic/' $SCRIPT_HOME/my_answer_file
sed -i 's/CONFIG_IRONIC_KS_PW=PW_PLACEHOLDER/CONFIG_IRONIC_KS_PW=ironic/' $SCRIPT_HOME/my_answer_file

sed -i 's/CONFIG_GNOCCHI_INSTALL=y/CONFIG_GNOCCHI_INSTALL=n/' $SCRIPT_HOME/my_answer_file
sed -i 's/CONFIG_AODH_INSTALL=y/CONFIG_AODH_INSTALL=n/' $SCRIPT_HOME/my_answer_file
sed -i 's/CONFIG_CEILOMETER_INSTALL=y/CONFIG_CEILOMETER_INSTALL=n/' $SCRIPT_HOME/my_answer_file

# install
packstack --answer-file=$SCRIPT_HOME/my_answer_file


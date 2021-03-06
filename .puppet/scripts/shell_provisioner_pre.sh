#!/bin/bash

set -e

OSTYPE="unknown"

if [ -x /usr/bin/lsb_release ]; then
  OSTYPE=$(lsb_release -i -s)
  CODENAME=$(lsb_release -sc)
elif [ -e /etc/redhat-release ]; then
  OSTYPE="RedHat"
else
  echo "Unsupported OS!" >&2
  exit 1
fi

# TODO: Support more than just CentOS as base box
if [ "$OSTYPE" != "RedHat" ] || [ "$OSTYPE" = "CentOS" ]; then
  echo "Unsupported OS!" >&2
  exit 1
fi

if [ ! -e /var/initial_update ]; then
    echo "Running initial upgrade"
# Disable initial update to prevent the kernel update bug
# https://bugs.centos.org/view.php?id=13453
# https://bugzilla.redhat.com/show_bug.cgi?id=1463241
#
#    yum update -y
    date > /var/initial_update
fi

if [ ! -e /etc/yum.repos.d/puppet5.repo ]; then
    echo "Installing Puppet 5 release repository..."
    yum install -y https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
fi

if ! rpm -q "puppet-agent" &>/dev/null; then
    echo "Installing Puppet 5..."
    yum install -y puppet-agent
fi

if [ `getenforce` = 'Enforcing' ]; then
    echo "Setting selinux to permissive"
    setenforce 0
fi

if grep -qP "^SELINUX=enforcing" /etc/sysconfig/selinux; then
    echo "Disabling selinux after reboot"
    sed -i 's/^\\(SELINUX=\\)enforcing/\\1disabled/' /etc/sysconfig/selinux
fi

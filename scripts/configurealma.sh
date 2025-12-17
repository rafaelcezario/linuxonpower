#!/usr/bin/bash
#
# Licensed Materials - Property of IBM
#
# 5747-XX8
#
# (C) Copyright IBM Corp. 2011 All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with
# IBM Corp.
#


#
# CONSTANTS AND DEFINITIONS
#
IBM_BASE=https://public.dhe.ibm.com/software/server/POWER/Linux/yum
AT_BASE=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at

# distro ids
centos="CentOS"
fedora="Fedora"
rhel="RedHatEnterprise"
sles="SUSE LINUX"
almalinux="AlmaLinux"

# gpg check status
rhel_gpg_check_on="1"
rhel_gpg_check_off="0"
sles_gpg_check_on="on"
sles_gpg_check_off="off"

# distro repos
# centos
centosbe_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/CentOS/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL7/")
centosle_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/CentOS/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL7/")
centos8_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/RHEL/8/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL8/")

#fedora
fedora_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/Fedora/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/Fedora22/")

#rhel
rhel6_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/RHEL/\$releasever/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL\$releasever")
rhel7_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/RHEL/\$releasever/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL\$releasever")
rhel8_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/RHEL/\$releasever/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL\$releasever")
rhel9_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/RHEL/\$releasever/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL\$releasever")
rhel10_repos=("IBM_Power_Tools|IBM_Power_Tools|${IBM_BASE}/OSS/RHEL/\$releasever/" "Advance_Toolchain|Advance Toolchain|${AT_BASE}/redhat/RHEL\$releasever")

#sles
sles11_repos=("IBM_Power_Tools|${IBM_BASE}/OSS/SLES/\$releasever_major/" "Advance Toolchain|${AT_BASE}/suse/SLES_\$releasever_major")
sles12_repos=("IBM_Power_Tools|${IBM_BASE}/OSS/SLES/\$releasever_major/" "Advance Toolchain|${AT_BASE}/suse/SLES_\$releasever_major")
sles15_repos=("IBM_Power_Tools|${IBM_BASE}/OSS/SLES/\$releasever_major/" "Advance Toolchain|${AT_BASE}/suse/SLES_\$releasever_major")
sles16_repos=("IBM_Power_Tools|${IBM_BASE}/OSS/SLES/\$releasever_major/" "Advance Toolchain|${AT_BASE}/suse/SLES_\$releasever_major")

repo_conf="/etc/ibm-power-repo.conf"
rhel_repofile="/etc/yum.repos.d/ibm-power-repo.repo"
centos_repofile=${rhel_repofile}
fedora_repofile=${rhel_repofile}
vendor_dir="/etc/zypp/vendors.d"
vendor_file="/etc/zypp/vendors.d/IBM.Power"


#
# CODE
#
# check for root user, and for tool prereqs
[[ `id -u` != "0" ]] && echo "This tool must be run as root." && exit 1

# licensing information file is not present: exit
[[ ! -f /opt/ibm/lop/notice ]] && echo "The licensing information file is not present. Go to http://www14.software.ibm.com/webapp/set2/sas/f/lopdiags/yum.html to get the ibm-power-repo RPM package which is the source for this script." && exit 1

# licensing information file is present: show it
less /opt/ibm/lop/notice

# user does not agree: exit
read -p "Do you agree with the above [y/n]? " -n 1 -r
echo

if [[ ! $REPLY = [Yy] ]] ; then
    exit 1
fi

# user agrees: configure repositories


if [ -f /etc/os-release ]; then
  source /etc/os-release
  release=$(echo $VERSION_ID | cut -d'.' -f1 | cut -d' ' -f1)
  if [[ $NAME == *"Red Hat"* ]]; then
    distro=$rhel
  elif [[ $NAME == *"AlmaLinux"* ]]; then
    distro=$almalinux
  elif [[ $NAME == *"SLES"* ]]; then
    distro=$sles
  elif [[ $NAME == *"Fedora"* ]]; then
    distro=$fedora
  elif [[ $NAME == *"CentOS"* ]]; then
    distro=$centos
  else
    distro=$centos
    echo "AlmaLinux"
   # echo "Distro not found"
    exit 1
  fi
fi

# -------------------------------------
# Check GPG
# -------------------------------------
# @type  $1: string
# @param $1: repository name
#
# @type  $2: string
# @param $2: architecture
#
# @type  $3: string
# @param $3: distro id
#
# @rtype: string
# @returns: gpg check status
# -------------------------------------
check_gpg()
{
  # AT repository in a X System: disable GPG check
  if [[ $1 == "Advance Toolchain" ]] && [[ $2 != ppc* ]] ; then

    # sles system: zypp file with gpg check off
    if [[ $3 == $sles ]] ; then
      echo $sles_gpg_check_off

    # other system: repo md file with gpg check off
    else
      echo $rhel_gpg_check_off
    fi

  # not X System or not AT repo: enable GPG check
  else

    # sles system: zypp file with gpg check on
    if [[ $3 == $sles ]] ; then
      echo $sles_gpg_check_on

    # other system: repo md file with gpg check on
    else
      echo $rhel_gpg_check_on
    fi

  fi
}

get_arch_id()
{
  local arch=`uname -m`

  if [ "$arch" = "ppc64le" ] ; then
    echo "ppc64le"
  elif [ "$arch" = "ppc64" ] ; then
    echo "ppc64"
  elif [ "$arch" = "ppc" ] ; then
    echo "ppc64"
  else
    echo "x86_64"
  fi
}

get_repo_arch()
{
  if [ "$1" = "Advance Toolchain" ] ; then
    echo ""
  else
    echo $(get_arch_id)
  fi
}

# -------------------------------------
# Configure CentOS repositories
# -------------------------------------
# @type  $1: list
# @param $1: repositories configuration
#
# @rtype: none
# @returns: nothing
# -------------------------------------
mk_centos_repos()
{
  # remove current configuration
  rm -f ${centos_repofile}

  # configure each repository
  for r in "$@"; do

    # get setup
    id=`echo $r | cut -d"|" -f 1`
    name=`echo $r | cut -d"|" -f 2`
    url=`echo $r | cut -d"|" -f 3`
    local arch=$(get_repo_arch "$name")

    # write on configuration file
    echo "[$id]" >> ${centos_repofile}
    echo "name=$name" >> ${centos_repofile}
    echo "baseurl=$url$arch" >> ${centos_repofile}
    echo "enabled=1" >> ${centos_repofile}

    # set gpg check accordingly
    local os_arch=$(get_arch_id)
    local gpgcheck=$(check_gpg "$name" "$os_arch" "$centos")
    echo "gpgcheck=$gpgcheck" >> ${centos_repofile}
    echo "gpgkey=$url$arch/repodata/repomd.xml.key" >> ${centos_repofile}
  done

  # add public gpg keys to the system
  /opt/ibm/lop/gpg/install_keys || true
}

mk_sles_repos()
{
  if [ -e ${repo_conf} ] ; then
    while read r
    do
      name=`echo $r | cut -d"|" -f 1`
      rm -f "/etc/zypp/repos.d/$name.repo"
    done < ${repo_conf}
  fi

  if [ ! -e ${vendor_dir} ] ; then
    mkdir -p ${vendor_dir}
  fi

  if [ ! -e ${vendor_file} ] ; then
    echo "[main]" > ${vendor_file}
    echo "" >> ${vendor_file}
    echo "vendors = SUSE,IBM" >> ${vendor_file}
  fi

  rm -f ${repo_conf}
  for r in "$@"; do
    echo "$r" >> ${repo_conf}
    name=`echo $r | cut -d"|" -f 1`
    url=`echo $r | cut -d"|" -f 2`
    local arch=$(get_repo_arch "$name")

    echo "[$name]" > "/etc/zypp/repos.d/$name.repo"
    echo "name=$name" >> "/etc/zypp/repos.d/$name.repo"
    echo "enabled=1" >> "/etc/zypp/repos.d/$name.repo"
    echo "autorefresh=1" >> "/etc/zypp/repos.d/$name.repo"
    echo "baseurl=$url$arch" >> "/etc/zypp/repos.d/$name.repo"
    echo "type=rpm-md" >> "/etc/zypp/repos.d/$name.repo"
    echo "keeppackages=0" >> "/etc/zypp/repos.d/$name.repo"

    # set gpg check accordingly
    local os_arch=$(get_arch_id)
    local gpgcheck=$(check_gpg "$name" "$os_arch" "$sles")
    echo "gpgcheck=$gpgcheck" >> "/etc/zypp/repos.d/$name.repo"
  done
}

mk_rhel_repos()
{
  rm -f ${rhel_repofile}

  for r in "$@"; do
    id=`echo $r | cut -d"|" -f 1`
    name=`echo $r | cut -d"|" -f 2`
    url=`echo $r | cut -d"|" -f 3`
    local arch=$(get_repo_arch "$name")

    echo "[$id]" >> ${rhel_repofile}
    echo "name=$name" >> ${rhel_repofile}
    echo "baseurl=$url$arch" >> ${rhel_repofile}
    echo "enabled=1" >> ${rhel_repofile}

    # set gpg check accordingly
    local os_arch=$(get_arch_id)
    local gpgcheck=$(check_gpg "$name" "$os_arch" "$rhel")
    echo "gpgcheck=$gpgcheck" >> ${rhel_repofile}
    echo "gpgkey=$url$arch/repodata/repomd.xml.key" >> ${rhel_repofile}
  done
}

mk_fedora_repos()
{
  rm -f ${fedora_repofile}

  for r in "$@"; do
    id=`echo $r | cut -d"|" -f 1`
    name=`echo $r | cut -d"|" -f 2`
    url=`echo $r | cut -d"|" -f 3`
    local arch=$(get_repo_arch "$name")

    echo "[$id]" >> ${fedora_repofile}
    echo "name=$name" >> ${fedora_repofile}
    echo "baseurl=$url$arch" >> ${fedora_repofile}
    echo "enabled=1" >> ${fedora_repofile}

    # set gpg check accordingly
    local os_arch=$(get_arch_id)
    local gpgcheck=$(check_gpg "$name" "$os_arch" "$fedora")
    echo "gpgcheck=$gpgcheck" >> ${fedora_repofile}
    echo "gpgkey=$url$arch/repodata/repomd.xml.key" >> ${fedora_repofile}

  done

  # add public gpg keys to the system
  /opt/ibm/lop/gpg/install_keys || true
}

if [ "$distro" = "SUSE LINUX" ]; then
  if [ "$release" = "11" ]; then
    mk_sles_repos "${sles11_repos[@]}"
  elif [ "$release" = "12" ]; then
    mk_sles_repos "${sles12_repos[@]}"
  elif [ "$release" = "15" ]; then
    mk_sles_repos "${sles15_repos[@]}"
  elif [ "$release" = "16" ]; then
    mk_sles_repos "${sles16_repos[@]}"
  fi

  if [ "$release"  -lt "16" ]; then
    nohup /opt/ibm/lop/gpg/install_keys -o 5 &>/dev/null &
  else
    nohup /opt/ibm/lop/gpg/install_keys 5 &>/dev/null &
  fi

elif [ "$distro" = "RedHatEnterprise" ]; then
  # RHEL release are major.minor so pick off the major info
  release=${release%%.*}
  if [ "$release" = "6" ]; then
    mk_rhel_repos "${rhel6_repos[@]}"
  elif [ "$release" = "7" ]; then
    mk_rhel_repos "${rhel7_repos[@]}"
  elif [ "$release" = "8" ]; then
    mk_rhel_repos "${rhel8_repos[@]}"
  elif [ "$release" = "9" ]; then
    mk_rhel_repos "${rhel9_repos[@]}"
  elif [ "$release" = "10" ]; then
    mk_rhel_repos "${rhel10_repos[@]}"
  fi

  if [ "$release" -lt "10" ]; then
    /opt/ibm/lop/gpg/install_keys -o || true
  else
    /opt/ibm/lop/gpg/install_keys || true
  fi

elif [ "$distro" = "AlmaLinux" ]; then
  # AlmaLinux é compatível com RHEL
  release=${release%%.*}

  echo "Configurando IBM Power Tools para AlmaLinux $release (usando repos RHEL)"

  if [ "$release" = "8" ]; then
    mk_rhel_repos "${rhel8_repos[@]}"
  elif [ "$release" = "9" ]; then
    mk_rhel_repos "${rhel9_repos[@]}"
  elif [ "$release" = "10" ]; then
    echo "⚠️ AlmaLinux 10 não possui repositório oficial IBM Power."
    echo "➡️ Usando repositórios RHEL 9 como fallback."
    mk_rhel_repos "${rhel9_repos[@]}"
  else
    echo "Versão AlmaLinux não suportada: $release"
    exit 1
  fi

  /opt/ibm/lop/gpg/install_keys || true


elif [ "$distro" = "Fedora" ]; then
  mk_fedora_repos "${fedora_repos[@]}"
elif [[ $distro == $centos ]] ; then

  # ppc64: add be repos
  arch_id=$(get_arch_id)

  if [ "$arch_id" = "ppc64" ] ; then
    mk_centos_repos "${centosbe_repos[@]}"

  # not ppc64: add le repos
  else
    if [ "$release" = "7" ]; then
      mk_centos_repos "${centosle_repos[@]}"
    elif [ "$release" = "8" ]; then
      mk_centos_repos "${centos8_repos[@]}"
    fi
  fi

fi

# clean motd message
/opt/ibm/lop/motd_cleaner

# success
exit 0

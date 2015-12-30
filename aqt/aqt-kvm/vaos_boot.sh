#!/bin/bash
# (c) Copyright 2011, 2012, 2013, 2014, 2015.  
# All Rights Reserved by VireoMD, Inc.,
# 1 Blackfield Drive #121, Tiburon, California, U.S.A.  94920
# 
#               CONFIDENTIAL, TRADE SECRET &
#           PROPRIETARY PROPERTY of VireoMD, Inc.
# Direct any questions to vireomd.inc@vireomd.net and/or 
# vireomd.inc@gmail.com.  Consult http://www.vireomd.com
#           
# All use of this file and/or any of its contents, in any way 
# whatsoever, is subject to the terms of the the VireoMD, Inc. 
# ExoWare license v1.0.  Consult the accompanying file 
# VireoMD_ExoWare_LICENSE_v1.0.txt for license details. 
# Alternatively, use a web browser to acccess details at 
# http://www.vireomd.net/licenses.  Additionally, contact 
# either vireomd.inc@vireomd.net or vireomd.inc@gmail.com 
# with any questions about the terms of these licenses - or - 
# for help accessing the details of this license.
#                
# If this file is discovered outside of a properly licensed 
# context, please report this to VireoMD, Inc.  If not expressly 
# and explicitly licensed to do so, DO NOT disclose, dissiminate, 
# reproduce, copy, share, transmit, distribute, cite or use this 
# file, nor any contents of this file, in any way whatsoever.
#
# If you are not licensed, in writing, to access this file, please 
# SECURELY DESTROY this file as soon as possible.  If you are not 
# properly licensed to access and use this file, and the contents 
# herein, make no use whatsoever either of this file or of this 
# file's contents.
#
# Unless specifically documented otherwise, in writing, and as both 
# signed and dated by a then current, corporate officer of VireoMD, 
# Inc., this file and all contents herein are subject to the terms 
# and conditions set forth by the license referenced above.  
#
# This file, or portions thereof, or this file in combination with 
# other VireoMD proprietary files, may be subject to existing,  
# provisional or other sorts of patents granted to VireoMD, Inc. 
# (in the U.S.A. and/or other countries around the world).  This file, 
# or portions thereof, may also be subject to planned or pending 
# patent petitions from VireoMD, Inc.
#
# This file, or this file in combination with other VireoMD, Inc. 
# proprietary files, is mission critical, disclosure-sensitive 
# and strategically differentiating to the busniss interests of 
# VireoMD Inc.  It is hereby understood that damages may be an 
# inadequate remedy in the event of a breach of the confidentiality 
# of this file (or of any portion of this file's contents), and that 
# any breach might cause VireoMD, Inc. irreparable harm and damage.  
# Accordingly, and to the extent permissible by applicable law,
# VireoMD, Inc. shall be entitled to injunctive and other equitable 
# relief, without waiving any additional rights or remedies available 
# at law or in equity or by statute.  
###
#
# Runs upon the first virtual machine 'boot' - and runs as root!
#
### USAGE
#  The firstboot script is copied into the newly minted domain/VA/VM, 
#  by vmbuilder, as /root/firstboot.sh.  It runs for an hour or two
#  ... to essentially 'inflate' the new domain/VA/VM.  One
#  can view progress while the new domain/VA/VM is inflating via 
#  the tail -f commandx.  Here's an example:
#    tail -f tail -f /home/vmdadmin/vaos_boot_20130108_17_40_15.log
#  While the /root/firstboot.sh script runs, you can log in 
#  and use the new domain/VA/VM, but you generally cannot 
#  manually/interactively run apt-get installs/etc.  During 
#  the first couple of hours of life for the newly minted 
#  domain/VA/VM, the running firstboot.sh script hogs the 
#  necessary apt repo/cache/etc. locks.  
#
### NOTES
#
#  Expire the vmbuilder created (first) account's password
#    Otherwise anyone with access to 
#    /var/lib/libvirt/images/[vmdv|vmdvs]/<VA VANA ID> 
#    directory, and the <VA VANA ID>.cfg file found there,
#    might see the vmbuilder-time password for that account.
#      passwd -e administrator
#    Notice that this creates a risk of a guest login trap 
#    - when/if there are any problems changing this first 
#    user account's password upon first login.  See 
#    git://t1/vaos/vaos.cfg for details about the guest 
#    login trap. 
# 
#  Wait for the network to come up - but beware of VM hang
#    For the temporary sake of expediency (and until VireoMD 
#    has the resources/funding/time to do better), vaos_boot.sh 
#    will assume a valid/working network connection.  For example, 
#    this will be required for apt-get install actions.  
#    
#    While this is awfully convenient/expedient, if the 
#    vmbuilder created VM does NOT manage to acquire a valid/working 
#    network configuration, and to find itself upon a 
#    KVM-host configured for bridged networking, and to 
#    find it's KVM-host attached to an internet-accessible 
#    LAN, then, the VM will hang forever.  
#      while (! ping -c 1 www.google.com); do sleep 1; done
#
#  Use apt-get dist-upgrade manually - when/if appropriate!  Beware!
#    VireoMD assumes voas_boot.sh will be used primarily and/or only 
#    with newly created, VireoMD-standard virtual appliances (VAs).  
#    Since VireoMD tracks Ubuntu releases pretty closely, it is 
#    usually O.K. to run apt-get dist-ugprade.  For example, this 
#    often helps bring in the latest Linux kernel.  Otherwise, apt 
#    can show this as a 'held back' package.  
#
#    However, it is NOT always O.K. to run apt-get dist-upgrade.  
#    For example, VireoMD tries to upgrade to new Ubuntu JEOS/Server 
#    releases when the corresponding *.1 release/version comes out.  
#    This means, for example, that a version like 12.10 can come out, 
#    and yet, VireoMD will wait a month or two for the 12.10.1 version 
#    to appear.  In this interregnum, VireoMD will continue to build 
#    new VAs on hosts running 12.04.  VireoMD-standard vmbuilder 
#    configuration files (like git://t1/vaos/vaos.cfg), will continue 
#    to reference 12.04.  So, during the period, running 
#    apt-get dist-upgrade (especially here in the vaos_boot.sh script)
#    is very likely to cripple/brick the affected virtual appliance (VA)  
#    whenever/ifever it is not on latest Ubuntu
#
#  Don't apt-get remove isc-dhcp-client
#    Unlike Ubuntu Server, VAs based on JeOS do not default to DCHP net cfg.
#    So here, there's no need to apt-get remove isc-dhcp-client.  You will 
#    find that in git://t1/hos/hos_boot.sh.  KVM-hosts are distinct from 
#    virtual appliances (VAs) that they host, although both are (VANA) platforms.
# 
#  Eschew local certificate authorities (CAs) everywhere
#    Proliferating (local) certificate authorities all over the 
#    place is a dubious plan at best.  It is not likely to be 
#    necessary.  But if this were to be desired (somewhere/somehow), 
#    then, the following commands might help get this done.  
#
#    These commands often prompt the user for input to a series 
#    of questions.  They must be run in the same singular shell 
#    session.  There are lots of export environment variable 
#    manipulating commands - so many of the following, cited scripts 
#    need to be 'sourced'.  Each script presumes the previous 
#    script has been run in the same, singular shell 'environment'.  
# 
#      cd /etc/openvpn/easy-rsa/2.0 
#      source /etc/openvpn/easy-rsa/2.0/vars 
#      source /etc/openvpn/easy-rsa/2.0/clean-all 
#      source /etc/openvpn/easy-rsa/2.0/build-ca
#      source /etc/openvpn/easy-rsa/2.0/build-key-server server
#
#    VireoMD-standard 'platforms' use the following pattern of repsonses
#    Organizational Unit Name (eg, section) []:viridis
#    Common Name (eg, your name or your server's hostname) [VireoMD CA]:sk_tsb65543 (see VANA) 
#    Name []:vmdadmin (the conventional VireoMD platform/va/host first user name)
#
#    Building client keys:
#      source /etc/openvpn/easy-rsa/2.0/build-key sch_d630
#    Client naming ought to be user initials_end-point-device-name
#    If more than one J.Q.S. (John Q. Smith) exists, then jqs2_<end-point> 
#    for one of them.  end-point-device-name is any mnemonic string for 
#    end user in question.  For SCH, d630 might be Steffen's (SCH's) 
#    old Dell D630 model laptop.
#
#    Building Diffie Helman parameters
#      source /etc/openvpn/easy-rsa/2.0/build-dh
#
#      cd /etc/openvpn/easy-rsa/2.0/keys
#      cp ca.crt ca.key dh2048.pem server.crt server.key /etc/openvpn
#      cd /usr/share/doc/openvpn/examples/sample-config-files
#      gunzip -d server.conf.gz
#      cp server.conf /etc/openvpn/
#      cp client.conf ~/
#
#    From /etc/openvpn/easy-rsa/2.0/keys, copy ca.crt, 
#    sch_d630.crt and sch_d630.key to SCH's Dell D630 laptop, etc.
#    Be sure to use ssh/scp (to protect/secure these in transmission).
#    The ~/client.conf file might handy too.
# 
#  Avoid xinetd 
#    Trying to install xinetd triggers some vmbuilder-time warnings 
#    about xinetd not being fully supported (perhaps by other packages 
#    needing to modify /etc/xinitd.conf vis some shared utility IIRC).
#    No wonder.  ubuntu packages are all about Upstart.  Why swim  
#    against the ubuntu Upstart current?  Thar be dragons this way ...
#
### Known Bugs and Work-arounds
#
#  git-el package 
#    When git-el was installed as a core package, via the long list 
#    of apt-get install -qqy core-package commands (see below), 
#    the particular apt-get install command seems as if it 
#    triggers this firstboot script to crash.  It seems as if 
#    if provokes a full OS crash.  Just as soon as this command 
#    is processed, the heretofore healthy openssh-server seems 
#    to terminate all exsiting ssh sessions/connections - and then 
#    to hang and attempts to initiate new ssh sessions/connections.  
#
#    On the other hand, when run by hand after 'inflation' (i.e. 
#    after the firstboot script completes), then, this command 
#    completes.  In this manual invocation case, the following 
#    command returns an exit status of 0 (success!).  Apparently, 
#    this is one package that cannot become part of VireoMD's 
#    Virtual Appliance Operating Ssytem (VAOS).  Beware!
#      apt-get install -qqy git-el 2>&1 | tee -a $VAOS_BOOT_LOG
# 
#    Work-around:  virsh reset <domain/VA, e.g. cep-tsb2>
#    This seems to emulate a hardware reset/interrupt, trigger 
#    a reboot, and start the /root/firstboot.sh script running 
#    all over again.  Fortunately, the second run of an 
#    affected firstboot script skips the dreaded command due 
#    to a subsequent error: 
#    cat /home/vmdadmin/vaos_boot_<date/time>.log
#    >>>
#    INFO: apt-get autoremove -qqy start now:
#    E: dpkg was interrupted, you must manually run 'dpkg --configure -a' to correct the problem. 
#    E: dpkg was interrupted, you must manually run 'dpkg --configure -a' to correct the problem. 
#    INFO: vaos_boot.sh run ends here:
#    <<<
#    Although the guest's vmdadmin password will be expired,
#    again, by the second run of the first boot script, nothing      
#    else should be harmed.  Rentrancy/re-runnability is a 
#    VireoMD design goal for firstboot scripts (like this one). 
#
### Future Directions (FDs)
#
#  Open up to the recursive operations center (ROC)
#    Start with a wget for the ssh keys (id_rsa.pub files) that 
#    need to be appended to vmdadmin's (and/or maybe root's) 
#    autorized_keys files (e.g. /home/vmdadmin/.ssh/authorized_keys).
#    This is the 'security' bootstrap for remote/secure (SSH) ROC 
#    login sessions ... which are initially used to get a ROC Daemon 
#    (ROCD) installed and running.  A generic (proto-)platform, 
#    whether vitual appliance (vA) or (KVM-)host, does not necessarily 
#    have a tier 2 ROC installed.  That comes via ROC 'provisioning'.  
#    That is part and parcel of tier 2.  This wget is just the segway 
#    that sets the stage for (and enables) all of tier 2 deployment 
#    (install/configuration).
#  Configure VA's to enable virsh console
#    http://now.ohah.net/setu/wiki.cgi?Ubuntu%3A10.04%3Asetup%3Abase0.console
#    The following needs to go into the <device> section of 
#    /etc/libvirt/qemu/<VM/domain name>.xml to tell libvirt 
#    about the VM's/domain's (virtual) serial console:
#      <serial type='pty'>
#        <target port='0'/>
#      </serial>
#      <console type='pty'>
#        <target type='serial' port='0'/>
#      </console>
#    It may be best to use some custom vmbuilder 
#    'template' that incorporates this static text 
#    in just the right place (as per virsh 
#    'edit <VM/domain name>').  See 
#    http://www.grosseosterhues.com/2011/03/using-vmbuilder-with-libvirt/
#
#    Then, the VM's linux upstart/init system needs 
#    to be configured to spawn a getty for
#    the (virtual) serial terminal - and to route console 
#    writes to this.  Next are edits to the grub2 config 
#    and some kernel boot paramters (so the Linux 
#    kernel knows about the serial console):
#      console=tty0 console=ttyS0,115200n8
#    The URL above illustrates all of these details.  It 
#    might not seem necessary, nor often helpful, but 
#    when/if ssh fails, having a virsh console option can 
#    sure be handy ;-)  Even virt-viewer is often used 
#    in conjunction with ssh (i.e. qemu+ssh:///), so 
#    virsh console can be a nice, simple, handy option.
#
#  Recursive Opeations Center Install/Config 
#    Contact SCH, RRR or TJB for details on the embryonic 
#    platform provisioning notions.  Platform provisioning 
#    is one of the responsibility of the recursive operations 
#    centers (ROCs).  These ROCs are organized into a ROC 
#    tree (i.e. hierarchy).  
# 
#    The root of the ROC tree is the sol-called 'ops' 
#    server/ROC.  Each ROC is composed of a certain 
#    web-based systems management software (SMS) 
#    appliation and a certain management agent type 'daemon' 
#    process.  Jobs are delegated throughout the ROC 
#    tree/hierarchy to affect distributed, collaborative 
#    processing.  A job that runs on only one node is 
#    just a degenerate case.  
#
#    Normally, each job applies to all of the ROC instances 
#    under a given ROC.  This is called the scope of 
#    application (SOA, or sphere of applicability or whatever).  
#    Long story.
#
#    The key idea is that each ROC Daemon (ROCD) runs all of the 
#    management/admin processing necessary for the local node ... 
#    and then supervises the delegation of all the rest of the 
#    required processin ... before rolling up the final results. 
#    VireoMD's ultimate-ROC, the so-called 'ops' server/VM, is 
#    rarely tasked ... since few 'jobs' have a global SOA .  
#
#    Files are also replicated across the ROC tree.  This way, 
#    necessary data files, packages, scripts, etc. can all be 
#    pre-positioned to support whatever jobs later need to 
#    reference them. 
#
#  PAM/Network-AAA:  Need a plan/configuration to integrate something
#    Reza suggests going with MS Active Directory Domain Controllers 
#    (mirrored) for the back-end (at VireoMD).  The proliferation 
#    of manually set/maintained passwords everywhere just does NOT 
#    scale.
#  update-motd:  Better 'context' might help cut down on human errors.  
#    Add legal warnings, assert ownership rights, copyright, license, etc.
#  SNPP:  Simple Network Paging Protocol package for python
#    Dropped out of Ubuntu 12.04.  That package was named python-snpp.
#    Bummer.  That promised to be handy for system admin stuff.
#  Multiverse:  A few VAOS components might the multiverse
#    sparse, python-sparse, python-pyopencl, python-pygpu 
#    See note above warning about multiverse package archive dependence.
#  QGIS: Was in Natty and Oneric, disappears in Precise (12.04).  
#    libqgis1.4.0, libqgis-dev, qgis-common, qgis, qgis-plugin-grass, 
#    qgis-plugin-grass-common, python-qgis-common, python-qgis 
#  X/GUI:  just in case some GUI utility (crutch?) helps
#    x11vnc installs and uses xvfb (in certain situations).  It can 
#    be used with the ssh/ssl (aware) vnc client called ssvnc.  
#    When a X/GUI is handy, Fluxbox is used as the X window 
#    manager (along with iDesk).  One 'head' (or GUI/screen) 
#    for a VireoMD platform/va/host is some remote, 
#    over-the-network, VNC-client taling to the x11vnc 
#    server that publishes a 'virtual' screen.  Another might 
#    be X client applications talking to a remote screen 
#    via ssh -X (X11 forwarding) tunnels.  
#    Someday, install/use ssvnc as a secure vnc client 
#    (on end-point devices).  Long story.  VireoMD should 
#    work-up a rich, remote GUI solution for VireoMD-standard,
#    headless hosts & VAs (i.e. VANA platforms).
#  build-essential: Remove this!  Security risk.  Attack surface
#    build-essential drags in GCC/g++ and who knows what all else.
#    This probably pulls in make, autotools, etc.  This is *not* 
#    a great move from a security standpoint.  Maybe ... someday.  
#    For now, this goes in just to make field operations quick, 
#    easy and convenient.  Just now, OpEx rules the day.  
#    This is just a timing thing.  For now, convenience means 
#    less OpEx risk.  This can be optimized later.
#    In particular, this can be later optimized for security. 
#    VireoMD must 'lock down' the THASA Cluster Node (TCN) 
#    type virtual appliances (VAs).  Having build-essential 
#    exposes a modest attack surface ... albeit only for those 
#    able to penetrate defense-in-depth layers like OpenVPN/OpenSSH.
#    For now, this is just some pragmatic horse trading!  
#  python-suds: SOAP call support - but maybe remove SOAPy stuff  
#    Generally, VireoMD discourages the use of SOAP.  VireoMD prefers 
#    RESTFul network services/resources.  But just in case, 
#    python-suds is included below.  It seems to be best of breed 
#    versus alternatives like python-soaplib, python-soappy, etc.
#    If SOAP ever becomes necessary, for any reason, 
#    this choice bears further analysis.  Consult SCH and others 
#    if you ever find a need to use SOAP (and/or include suds)
#  whiptail and xz-utils:  Implicit?
#    Both whiptail and xz-utils seem to be part of Ubuntu's Just-enough 
#    Operating System (JEOS or JeOS).  This is pronounced 'juice'.  
#    JeOS is the baseline for any VM created via vmbuilder.  Still, 
#    it may help make vaos_boot.sh a bot more self documenting to add 
#    some apt-get install -qqy commands.
#  Kerberos:  An embroglio that needs a good justification!
#    libpam-krb5 package seems to destabilize the JeOS's chpasswd 
#    command.  Once I refrained from installing these krb5 packages, 
#    vmbuilder quit spitting up errors that looked like this:
#       VMBuilder.exception.VMBuilderException: 
#         Process (['chroot', '/tmp/tmpjaaLlV', 'chpasswd']) returned 1. 
#         stdout: , stderr: Password unchanged
#       chpasswd: (user vmdadmin) pam_chauthtok() failed, error:
#       Authentication token manipulation error
#       chpasswd: (line 1, user vmdadmin) password not changed
#    Somehow, under Ubuntu 12.04, one could install many krb5/kerberos 
#    packages non-interactively. But in Ubuntu 12.10, not so much.
#    I ran into interactive prompts to confirm the default kerberos 5 
#    realm.  So ... do NOT put anything like the following in vaos_boot.sh:
#        apt-get install -qqy krb5-user 2>&1 | tee -a $VAOS_BOOT_LOG
#  python-cjson: conflicts with python-kombu 
#    Breaks: python-cjson (<= 1.0.5-4+b1) but 1.0.5-4build1 is to be installed
#    So ... yank python-cjson (or swap it in after removing/purging 
#    python-kombu).  This looks like a package name abbreviation flub on 
#    Debian or Canonical's part.  Maybe it will get fixed someday.  I 
#    probably should file an ubuntu bug about it, but until VireoMD 
#    feels a need for python-cjson's 'speed', I'll let this annoyance 
#    slide.
#  python-pyxattr:  conflicts with python-xattr
#    Since python-fs depends upon python-pyxattr, go with that.  Deferred 
#    python-pyxattr
#  libsiloh5-0:  See overview -->  https://en.wikipedia.org/wiki/Silo_(library)
#    Depends: libhdf5-openmpi-1.8.4 but MPI is not going to be installed.
#    Its hard to imagine VireoMD ever needing silo.  So, defer the following:  
#    libsilo-bin, libsilo-dev, libsiloh5-0, python-silo, 
#  strace64:i386: 
#    Depends:  libc6-amd64:i386 (>= 2.4) but that 32-bit stuff is 
#    not going to be installed.  The usual strace provided by 
#    Ubuntu (https://wiki.ubuntu.com/Strace) should be enough.  
#    Besides, strace64 seems to depend on eglibc:
#    https://launchpad.net/ubuntu/+source/eglibc.  Instead, install 
#    just the usual (https://wiki.ubuntu.com/Strace - via 
#    https://launchpad.net/ubuntu/+source/strace), and NOT strace64.
#  Dev-Workstation (host) additions
#    ssnvc, idle, buildbot, buildbot-slave
#    Also, lots of *-dbg packages (maybe - as needed).
#    wxwidgets? kivy (see http://kivy.org)
#    python-traitsbackendwx
#    If dragging in QT:  python-traitsbackendqt, transmision-qt
#    If TeX or LaTeX matters, see http://tug.org/texworks
#    and consider texworks-sripting-python.
#    For file backup, maybe pybackpack.
#    For Biliography work (http://pybliographer.org/),
#    try pybliographer.
#    Here's a bunch of other packages:
#      antlr-doc, pythoncard-doc, python-distribute-doc,
#      python-gevent-doc, graphviz-doc, icu-doc, 
#      libexiv2-doc, libgdal-doc, python-nose-doc, 
#      libpam-python-doc, mapnik-doc, opencv-doc, plplot-doc, 
#      python-reportlab-doc, python-vigra-doc,
#      r-base-html, r-doc-html, r-doc-pdf,  
#      python-scientific-doc, python-scrapy-doc, python-setupdocs,
#      libgeos-doc, python-simpleparse-doc, python-simpy-doc,
#      python-sip-doc, slides-doc, python-sparse-examples, 
#      sphinx-doc, python-celery-doc, python-sqlalchemy-doc,
#      libhdf5-doc, python-tables-doc, tidy-doc, 
#      python-tweepy-doc, libvigraimpex-doc, python-vigra-doc,
#      python-whoosh-doc, xapian-doc, liblzma-doc, pyro-doc,
#      pyro-examples, pyxplot-doc, wx2.8-doc, wx2.8-examples,
#      libsvn-doc, quantlib-examples
#
### HISTORY
#
# 20110511 SCH  Created (based on earlier boot.sh versions)
#               Added easy_install PyUtilib for platform
#               provisioning framework (PPF).  This isn't 
#               packaged for Ubuntu/Debian (as a *.deb).
# 20120814 SCH  Added easy_install yapsy for PPF (aka prov_rocd.py).
#               PyUtilib just wasn't as well documented - 
#               nor perhaps quite as well matched to the 
#               peculiar needs of distributed platform 
#               provisioning (via 'prov' jobs facilitated 
#               by recursive operations centers - ROCs).
#               However, TJB was able to get pyutilib working.
#               So, perhaps, go back to pyutilib ASAP.
# 20121101 SCH  Add some client keepalive configuration 
#               settings for /etc/ssh/sshd_config
# 20121102 SCH  Make sure vmdadmin is in the www-data group. 
#               This makes a lot of sense - and it promises to 
#               help lsyncd/cysnc2-driven file 
#               clustering/replication gain access to the 
#               necessary files/directories under 
#               /var/www/openemr.  Ask TJB for the 
#               motivating details!
# 20130107 SCH  A vmbuilder bug introduced with Ubuntu 12.10 
#               forces us to do all of the VireoMD virtual 
#               appliance (VA) operating system (VAOS) standard 
#               installs here in the vmbuilder 'firstboot' 
#               script.  To do this, I've added a boat laod 
#               of package installs to this script.
# 20150219 GSH  Modified for $VAOS_BOOT_LOG and $VAOS_BOOT_TRACE 
#               for AQT VMs.
#
#### Bash Script Prelude
#
#   Assumes a shebang line above (as first line, at top).  See
#   http://gfxmonk.net/2012/06/17/my-new-bash-script-prelude.html
#
# Use the trailing BASHPID to keep script runs, at the same 
# second/nanosecond, from overwriting each others log|trc files
# and to identify a hanging script's PID.
NOW=$(date +"%Y%m%d_%H_%M_%S_%N")"_$BASHPID"
VAOS_BOOT_LOG="/home/tester/vaos_boot_"$NOW".log" 
VAOS_BOOT_TRACE="/home/tester/vaos_boot_"$NOW".trc" 
export PS4='+ $(basename "$0")[$$] ${FUNCNAME[0]:+${FUNCNAME[0]}():}line ${LINENO}: '
exec 3<> "$VAOS_BOOT_TRACE"
BASH_XTRACEFD=3
# Use set -e to fail when any subcommand fails.  
# Here, in a firstboot script, it is often (or maybe) best to forge ahead!
# set -e
# Use set -u to fail when an unkown variable is referenced.
# There should NEVER be any unknown/uninitialized variables
# in a firstboot script, so if we hit one, exit!  Do not 
# just hang the firstboot.sh script.  
set -u
# Use set -o pipefail to fail an entire pipeline when any part fails.
# Here, in a firstboot script, it is probably best to forge ahead!  
# set -o pipefail
# Use set -x for bash script execution tracing. 
# The following can be shortened to set -x, undo this with 
# set +x.  By the way, set -o verbose (or set -v) echoes 
# out script comment lines as well but this -v bash option 
# does not honor/use $PS4.  So, use set -x alone  
# (rather than set -xv).  Lets set it once, here, in it's 
# full form, just to self-document what set -x does
set -o xtrace 
### start
echo INFO:  vaos_boot.sh start at $NOW here: 2>&1 | tee $VAOS_BOOT_LOG
echo " " 2>&1 | tee -a $VAOS_BOOT_LOG
set -x
# Expire first password, but beware guest login trap
# To debug guest login  trap, try commenting out passwd -e line
passwd -e vmdadmin 2>&1 | tee -a $VAOS_BOOT_LOG
adduser vmdadmin www-data 2>&1 | tee -a $VAOS_BOOT_LOG
# ... and just to be double sure ...
adduser vmdadmin sudo 2>&1 | tee -a $VAOS_BOOT_LOG
# Make sure that the /home/vmdadmin/.ssh/authorized_keys file is set up 
# correctly for passwordless login by the vmdadmin@KVM-host and 
# schulegaard@KVM-host accounts.  This is something of a backdoor 
# for the infamous, so-called guest login trap (see above).  Any *tiny* 
# deviation in the permissions, ownership (and who knows what all) 
# in the setup of the authorized_keys file will disable the 
# intended passwordless logins.  Normally, this is why ssh-copy-id 
# is such a recommended/preferred command.  
# 
# Aside from this one, rarely critical use, this passwordless login 
# set up is little more than infrequent convenience.  After all, 
# the vmdadmin@KVM-host and schulegaard@KVM-host accounts are rarely used.
# First, lets use a side-effect of ssh-keygen to ensure that this guest's 
# vmdadmin account has a /home/vmdadmin/.ssh directory.
(su -l vmdadmin -c "ssh-keygen -t rsa -N \"\" -f /home/vmdadmin/.ssh/id_rsa") 2>&1 | tee -a $VAOS_BOOT_LOG
if [ -d /home/vmdadmin/.ssh ]; then
    echo INFO:  Excellent.  ssh-keygen worked as expected for vmdadmin.  2>&1 | tee -a $VAOS_BOOT_LOG
    ls -ld /home/vmdadmin 2>&1 | tee -a $VAOS_BOOT_LOG
else
    echo INFO:  Weird, but ssh-keygen did not seem to work for vmdadmin.  Forging ahead.  No worries.  2>&1 | tee -a $VAOS_BOOT_LOG
    mkdir /home/vmdadmin/.ssh 2>&1 | tee -a $VAOS_BOOT_LOG
    chown vmdadmin:vmdadmin /home/vmdadmin/.ssh 2>&1 | tee -a $VAOS_BOOT_LOG
    chmod 700 /home/vmdadmin/.ssh 2>&1 | tee -a $VAOS_BOOT_LOG
fi
# One way or another, the /home/vmdadmin/.ssh directory should now exist!
if [ -d /home/vmdadmin/.ssh ]; then
    if [ -f /root/vmdadmin_at_kvm_host_id_rsa.pub ]; then
        echo INFO:  Copy vmdadmin@kvm-host id_rsa.pub to local vmdadmin authorized_keys file 2>&1 | tee -a $VAOS_BOOT_LOG
        (cat /root/vmdadmin_at_kvm_host_id_rsa.pub >> /home/vmdadmin/.ssh/authorized_keys) 2>&1 | tee -a $VAOS_BOOT_LOG
    else
        echo INFO:  No vmdadmin@kvm-host id_rsa.pub file found.  Ignore omission  2>&1 | tee -a $VAOS_BOOT_LOG
    fi
    if [ -f /root/schulegaard_at_kvm_host_id_rsa.pub ]; then
        echo INFO:  Copy schulegaard@kvm-host id_rsa.pub to local vmdadmin authorized_keys file 2>&1 | tee -a $VAOS_BOOT_LOG
        (cat /root/schulegaard_at_kvm_host_id_rsa.pub >> /home/vmdadmin/.ssh/authorized_keys) 2>&1 | tee -a $VAOS_BOOT_LOG
    else
        echo INFO:  No schulegaard@kvm-host id_rsa.pub file found.  Ignore omission  2>&1 | tee -a $VAOS_BOOT_LOG
    fi
    if [ -f /home/vmdadmin/.ssh/authorized_keys ]; then
        chown vmdadmin:vmdadmin /home/vmdadmin/.ssh/authorized_keys 2>&1 | tee -a $VAOS_BOOT_LOG
        chmod 600 /home/vmdadmin/.ssh/authorized_keys 2>&1 | tee -a $VAOS_BOOT_LOG
    fi
else
    echo "EXCEPT:  Trouble creating /home/vmdadmin/.ssh directory.  Skipping, but how did this happen?" 2>&1 | tee -a $VAOS_BOOT_LOG
fi
# Now, wait for network to come up, but beware VM hang risk (see above) 
while (! ping -c 1 www.google.com); do sleep 1; done
# Level set.  Use apt-get dist-upgrade manually (see note above) but BEWARE!
echo INFO:  apt-get update -qqy start now: 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get update -qqy 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  apt-get upgrade -qqy start now: 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get upgrade -qqy 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  apt-get autoremove -qqy start now: 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get autoremove -qqy 2>&1 | tee -a $VAOS_BOOT_LOG
set +x
#
### Install enabling virtual appliance (VA) access packages/facilities 
#
set -x
# Install openssh-server 
apt-get install -qqy openssh-server 2>&1 | tee -a $VAOS_BOOT_LOG
# Configure openssh-server
SSHD_CFG_FILE="/etc/ssh/sshd_config"
fgrep -i ClientAliveInterval $SSHD_CFG_FILE
if [ $? != "0" ]; then
    fgrep -i ClientAliveCountMax $SSHD_CFG_FILE 
    if [ $? != "0" ]; then
        echo INFO:  Setting ClientAlive* directives in $SSHD_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG  
        echo " " >> $SSHD_CFG_FILE
        echo "# 20130103 SCH  Try to keep all connected clients alive" >> $SSHD_CFG_FILE
        echo "ClientAliveInterval 180" >> $SSHD_CFG_FILE
        echo "ClientAliveCountMax 10" >> $SSHD_CFG_FILE
        echo " " >> $SSHD_CFG_FILE
    else
        echo INFO:  Skipping reset of ClientAlive* directives in $SSHD_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
    fi
else
    echo INFO:  Skipping override of any ClientAlive* directives in $SSHD_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
fi
echo INFO:  Dump of $SSHD_CFG_FILE starts here: 2>&1 | tee -a $VAOS_BOOT_LOG
cat $SSHD_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  Dump of $SSHD_CFG_FILE ends here: 2>&1 | tee -a $VAOS_BOOT_LOG
unset SSHD_CFG_FILE
service ssh restart 2>&1 | tee -a $VAOS_BOOT_LOG
# 20120103 SCH Slow down the Grub boot menu to a more 
#              convenient, and more forgiving, speed
GRUB_CFG_FILE="/etc/default/grub"
if [ -d $GRUB_CFG_FILE.orig ]; then
    cp $GRUB_CFG_FILE $GRUB_CFG_FILE.bk$NOW 2>&1 | tee -a $VAOS_BOOT_LOG
else
    cp $GRUB_CFG_FILE $GRUB_CFG_FILE.orig 2>&1 | tee -a $VAOS_BOOT_LOG
fi
sed -i 's/\(GRUB_TIMEOUT\s*=\s*\).*$/\18/g' /etc/default/grub
update-grub 2>&1 | tee -a $VAOS_BOOT_LOG
unset GRUB_CFG_FILE
# Elaborate on this host's default locale
(echo 'LANGUAGE="en_US.UTF-8"' >> /etc/default/locale) 2>&1 | tee -a $VAOS_BOOT_LOG
(echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale) 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  Dump /etc/default/locale starts here: 2>&1 | tee -a $HOS_BOOT_LOG
cat /etc/default/locale 2>&1 | tee -a $HOS_BOOT_LOG
echo INFO:  Dump /etc/default/locale ends here: 2>&1 | tee -a $HOS_BOOT_LOG
#
# Install OpenVPN 
#   Just handy to have if it ever needs to run platform/va co-resident
apt-get install -qqy openvpn 2>&1 | tee -a $VAOS_BOOT_LOG
# Parameterize OpenVPN defaults for subsequent, manual
# configuration (and use) on this 'platform'.  The first
# copy command prevents updates/upgrades of
# OpenVPN (the package) from overwriting any local default
# settings, configuration settings, keys, etc. 
OVPN_DEST=/etc/openvpn
if [ -d $OVPN_DEST/easy-rsa ];  then
    echo INFO:  $OVPN_DEST/easy-rsa already initialized.  Leaving this as is. 2>&1 | tee -a $VAOS_BOOT_LOG
else
    cp -R /usr/share/doc/openvpn/examples/easy-rsa/ ${OVPN_DEST} 2>&1 | tee -a $VAOS_BOOT_LOG
fi
OVPN_VARS=${OVPN_DEST}/easy-rsa/2.0/vars
# Be paranoid about KEY_SIZE for one time PKI negotiation
sed -i 's/\(KEY_SIZE\s*=\s*\).*$/\12048/g' ${OVPN_VARS}
# Comment out expiration days for certificate authority CA keys
# sed -i 's/^\(\s*export\s*CA_EXPIRE\s*=\s*\)/#\1/g' ${VARS}
# Oops.  That didn't work, so bump CA_EXPIRE up to 100 years worth of days
sed -i 's/^\(\s*export\s*CA_EXPIRE\s*=\s*\).*$/\136500/g' ${OVPN_VARS}
# Comment out expiration days for other keys
# sed -i 's/^\(\s*export\s*KEY_EXPIRE\s*=\s*\)/#\1/g' ${OVPN_VARS}
# Oops.  That didn't work any better than the previous one, so ...
sed -i 's/^\(\s*export\s*KEY_EXPIRE\s*=\s*\).*$/\136500/g' ${OVPN_VARS}
# Now set the VireoMD standard values for fields to be placed in the certificate
sed -i 's/\(KEY_COUNTRY\s*=\s*\).*$/\1\"US\"/g' ${OVPN_VARS}
sed -i 's/\(KEY_PROVINCE\s*=\s*\).*$/\1\"CA\"/g' ${OVPN_VARS}
sed -i 's/\(KEY_CITY\s*=\s*\).*$/\1\"Tiburon\"/g' ${OVPN_VARS}
sed -i 's/\(KEY_ORG\s*=\s*\).*$/\1\"VireoMD\"/g' ${OVPN_VARS}
sed -i 's/\(KEY_EMAIL\s*=\s*\).*$/\1\"vireomd.inc@vireomd.net\"/g' ${OVPN_VARS}
echo INFO:  Dump of $OVPN_VARS starts here: 2>&1 | tee -a $VAOS_BOOT_LOG
cat ${OVPN_VARS} 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  Dump of $OVPN_VARS ends here: 2>&1 | tee -a $VAOS_BOOT_LOG
unset OVPN_DEST
unset OVPN_VARS
# The platform provisioning framework (PFF), or others,  might want to build 
# a local certificate authority (CA) for OpenVPN ... in some
# cases/scenarios.  See the note above.  Much of this is interactive.
# Since it is suited for unattended/batch execution, it cannot be 
# done here in vaos_boot.sh - even if this were desired (and that is 
# dubious at best). 
#
# Even so, never be tempted to use vmbuilder's first login script for 
# such interactive installs/configs.  The timing of first logins 
# are unpredictable events ;-)
#
apt-get install -qqy update-manager-core 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy acpid 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unattended-upgrades 2>&1 | tee -a $VAOS_BOOT_LOG
set +x
# 
### Install core VireoMD-standard VAOS packages/facilities
# 
set -x
echo INFO:  Begin install of core, VireoMD-standard VAOS packages here:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy hwinfo 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy lshw 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy hardinfo 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy udev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ccrypt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy emacs 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy vim-nox 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy vim-scripts 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy vim-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy vim-latexsuite 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy build-essential 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy m4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gfortran 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgfortran3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy wget 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy dnsutils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy lynx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy apt-show-versions 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tmux 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy screen 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy supervisor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy htop 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy sysstat 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy memstat 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy bmon 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy iftop 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pktstat 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy iperf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tcptrack 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy whois 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy traceroute 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy paris-traceroute 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy nmap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy dnsutils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ipfm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ifstat 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy dstat 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ipband 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy iptraf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ethstatus 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy nload 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tcpflow 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ntp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy sharutils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy sharutils-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unace 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy zip 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unzip 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy p7zip-full 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy uudeview 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy mpack 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy arj 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy cabextract 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy dos2unix 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tofrodos 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy bashdb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libzmq-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libzmq1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy git 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy git-doc 2>&1 | tee -a $VAOS_BOOT_LOG
# 20130109 SCH At this point, the new cep-tsb2 hangs and 
#              drops ssh connections.  This is reproducible.
#              Removing this package, here, coincided with 
#              fixing this problem.  See optional section 
#              below, at the very end, where this was 
#              retried, albeit to no avail.  If you need 
#              the git-el package, run it interactively
#              (and perhaps AFTER this script finishes).
#              DO NOT uncomment the following line!
# apt-get install -qqy git-el 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy git-email 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gitolite 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xorg 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xorg-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xbase-clients 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xutils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy x11vnc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy fluxbox 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy idesk 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy conky-std 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xfe 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy slim 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy lsyncd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy csync2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy rsync 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy autossh 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy openvpn 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy iptables 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-cookie 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-easing 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-event-drag 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-event-drop 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-fancybox 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-form 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-galleriffic 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-history 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-jfeed 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-jush 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-livequery 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-meiomask 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-metadata 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-mousewheel 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-opacityrollover 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-tablesorter 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-tipsy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-jquery-treetable 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmsgpack-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmsgpack3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmsgpackc2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy msgpack-python 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy fabric 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pybtex 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pydb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pychecker 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  1st ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pydf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyecm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyflakes 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyg 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pep8 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pylint 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pymetrics 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyroman 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-git 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dulwich 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy aptitude 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dumbnet 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-elixir 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-encutils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ethtool 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy exactimage 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-exactimage 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-eyed3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-facebook 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-faulthandler 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libexif12 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libexif-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy exif 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-exif 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-feedparser 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-fs 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ftputil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-kitchen 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy antlr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libantlr-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libantlr-java 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libantlr2.7-cil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-antlr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-argparse 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-argvalidate 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-aspects 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pythoncard 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pythoncard-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-celery 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-changesettings 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-chardet 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-crypto 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy dialog 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dialog 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dicom 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dingus 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dkim 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-daemon 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-decorator 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dhm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-audit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-beaker 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-bitarray 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-buffy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ldap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsnmp-python 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dateutil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-magic 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-jinja2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-enum 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-docutils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-roman 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-adodb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-babel 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libapache2-mod-wsgi 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libapache2-mod-python 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libapache2-mod-python-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-numpy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-matplotlib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-matplotlib-data 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ipython 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-virtualenv 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy winpdb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyro 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyro-gui 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-greenlet 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libevent-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libevent-core-2.0-5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libevent-2.0-5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libevent-extra-2.0-5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libevent-openssl-2.0-5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libevent-pthreads-2.0-5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gevent 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gevent-dbg 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-greenlet-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-greenlet-dbg 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gunicorn 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-httplib2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python3-httplib2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mysqldb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-webob 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pylint 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-lxml 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-anyjson 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-apt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-apt-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-boto 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-bottle 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  2nd ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-beautifulsoup 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-flask 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mechanize 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openid 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-eventlet 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy rst2pdf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-uniconvertor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-m2crypto 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-configobj 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-cerealizer 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-distribute-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dns 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-dnspython 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mock 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpam-python 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgdal1-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gdal-bin 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gdal 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gdata 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gdata-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgdcm2.0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgdcm2-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgdcm-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgdcm-cil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libvtkgdcm2-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libvtkgdcm-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libvtkgdcm-cil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-vtkgdcm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gdcm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gnuplot 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gnuplot 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-geohash 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-geoip 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gmpy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gnupginterface 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gnutls 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-goopy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gpgme 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-graphy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gudev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-gvgen 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy html2text 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-html5lib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-imaging 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-imaging-sane 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-iowait 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ipaddr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-iptcdata 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-joblib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-jsonpickle 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-jsonrpc2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-keyczar 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-keyring 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-kjbuckets 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-kombu 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-landslide 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-lasso 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ldns 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-levenshtein 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libapparmor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libcloud 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-liblcms 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-liblicense 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libproxy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libsmbios 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libssh2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libsvm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libtorrent 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libxml2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libxml2-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libxml2-utils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libxml2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-libxslt1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-llfuse 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-llvm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-lockfile 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-loggingx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-logilab-astng 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-logilab-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-logilab-constraint 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-louie 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy lzma 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-lzma 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mailer 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmapnik2-2.0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmapnik2-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy mapnik-utils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mapnik2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mapscript 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-markdown 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-markupsafe 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mdp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mechanize 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-meld3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-meliae 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy memcached 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmemcached-tools 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  3rd ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmemcachedprotocol0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-memcache 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-meminfo-total 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmhash2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mhash 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-migrate 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libming1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libming-util 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ming-fonts-dejavu 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ming-fonts-opensymbol 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ming 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-minimock 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mock 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mode 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmosquitto0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy mosquitto-clients 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmosquittopp0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy mosquitto 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mosquitto 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mox 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mpmath 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-munkres 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mutagen 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mvpa-lib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-mvpa 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libncap44 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ncaptool 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ncap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ncrypt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-netaddr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy netcdf-bin 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-netcdf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-netfilter 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-netifaces 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-networkx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-networkx-doc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libnewt-pic 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-newt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nibabel 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nipy-lib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nipy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nipype 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nitime 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy nmap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nmap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nodebox-web 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-nose 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-numexpr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-oauth 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-oauth2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy graphviz 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy graphviz-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcdt4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcgraph5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgraph4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgraphviz-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgv-python 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgvc5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgvc5-plugins-gtk 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgvpr1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpathplan4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libxdot4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-objgraph 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcv2.3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcv-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcvaux2.3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcvaux-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libhighgui2.3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libhighgui-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-calib3d2.3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-calib3d-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-contrib2.3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-contrib-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-core2.3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-core-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopencv-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-opencv 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openid 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openopt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openpyxl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopenscap1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libopenscap-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openscap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libssl1.0.0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy openssl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openssl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-openturns 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libotr2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libotr2-bin 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-otr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpacparser1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pacparser 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpam-cracklib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pam 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-parallel 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-paramiko 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-parsedatetime 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-paste 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pastedeploy 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  4th ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pastescript 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pastewebkit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpcap0.8 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tcpdump 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy lsof 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pcapy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pcs 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pdftools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-peak.rules 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-peak.util 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-peak.util.decorator 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pebl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pefile 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pesto 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pexpect 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pip 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pipeline 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pisa 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-piston-mini-client 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pkg-resources 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy latex2html 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-plastex 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcsiro0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libplplot11 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libplplot-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy plplot11-driver-wxwidgets 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy plplot11-driver-xwin 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy plplot11-driver-gd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy plplot11-driver-cairo 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-plplot 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy autopoint 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gettext-base 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gettext 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gettext-el 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-polib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-poster 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pqueue 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcap-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-prctl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-prettytable 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-problem-report 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-profiler 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-progressbar 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libprotobuf-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libprotobuf7 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libprotoc-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libprotoc7 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy protobuf-compiler 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-protobuf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-protobuf.socketrpc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-prowlpy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-psutil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-psycopg2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy strace 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ptrace 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pudb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-py 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyasn1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pybabel 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pybiggles 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pycallgraph 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pycha 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pychart 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pycountry 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcrypto++-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcrypto++-utils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcrypto++9 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pycryptopp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy curl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcurl3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcurl3-gnutls 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcurl3-nss 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pycurl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pydoctor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pydot 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyentropy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyevolve 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy exiv2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libexiv2-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyexiv2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libfann2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libfann-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyfann 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyfiglet 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libboost-all-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pygccxml 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libglew1.6-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy glew-utils 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libglewmx1.6 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libglewmx1.6-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy grace 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pygrace 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pygments 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pygraph 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pygraphviz 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libicu48 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libicu-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyicu 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  5th ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy inotify-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy incron 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy inoticoming 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy inosync 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy iwatch 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-inotifyx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyinotify 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyip 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy isomd5sum 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyisomd5sum 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy opensc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pykcs11 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyke 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pylibmc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyme 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsnmp-base 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsnmp-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsnmp-python 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsnmp15 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy snmp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy snmpd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pynetsnmp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pynn 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyodbc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libode1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libode1sp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libode-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyode 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyparsing 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pypcap 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pypdf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyproj 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyquery 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyrad 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy librrd4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy librrd-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy rrdcached 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy rrdtool 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyrrd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyrss2gen 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpcsclite1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libpcsclite-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pcscd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyscard 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyscript 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyside 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pysnmp-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pysnmp4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pysnmp4-apps 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pysnmp4-mibs 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsqlite3-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy sqlite3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-apsw 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pysqlite 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pytest-xdist 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy imagemagick 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmagick++-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmagickcore-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libmagickwand-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pythonmagick 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pytools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libudev-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgudev-1.0-0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgudev-1.0-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy gir1.2-gudev-1.0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyudev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pywapi 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pywbem 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pywt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-pyxmpp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libqrencode-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libqrencode3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy qrencode 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-qrencode 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-radix 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-rbtools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy krb5-locales 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy krb5-pkinit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgssapi-krb5-2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libk5crypto3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libkrb5support0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libkrb5-3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libkrb5-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-kerberos 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libremctl-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libremctl1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy remctl-client 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy remctl-server 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-remctl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libfreetype6 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libfreetype6-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-renderpm 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-reportlab-accel 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-reportlab 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-requests 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-restkit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-restrictedpython 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-roman 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  6th ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-rope 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pymacs 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-ropemacs 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-routes 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy r-recommended 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy r-base-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy r-mathlib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ess 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy r-doc-info 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-rpy2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-rrdtool 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scapy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scientific 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scipy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scitools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sclapp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scour 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scrapy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-scriptutil 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sendfile 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-setproctitle 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-setuptools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgeos-c1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libgeos-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-shapely 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sigmask 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-simplegeneric 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-simplejson 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-simpleparse 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-simpleparse-mxtexttools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-simpy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-simpy-gui 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sip 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sip-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sleekxmpp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy s5 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-slides 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-slimmer 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-socksipy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-software-properties 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy sphinx-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libjs-sphinxdoc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sphinx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libspread1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libspread1-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy spread 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sprox 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sqlalchemy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sqlalchemy-ext 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sqlparse 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libstatgrab6 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy statgrab 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy saidar 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-statgrab 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-stdeb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-stdnum 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-stepic 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-stfio 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libstfl0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libstfl-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-stfl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-stompy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-subnettree 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsubunit0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsubunit-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcppunit-subunit0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcppunit-subunit-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libsubunit-perl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy subunit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-subunit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy subversion 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-subversion 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-suds 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-support 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcln6 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libcln-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pi 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libginac2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libginac-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ginac-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-swiginac 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-symeig 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-sympy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libhdf5-serial-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy hdf5-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tables 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tempita 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-testtools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tftpy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tickcount 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libtidy-0.99-0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libtidy-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tidy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tidylib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tlslite 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy tor-geoipdb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-torctl 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tornado 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  7th ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-toscawidgets 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tracer 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pythontracer 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tracing 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-traits 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-traitsbackendwx 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-traitsgui 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-translationstring 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy transmission-daemon 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy transmission-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy transmission-cli 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy transmission-gtk 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy transmission 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-transmissionrpc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-trml2pdf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tweepy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-twill 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-twitter 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-tz 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libunac1 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libunac1-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unaccent 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-unac 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libunbound-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libunbound2 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unbound-anchor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unbound-host 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-unbound 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-uniconvertor 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libwv-1.2-4 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libwv-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy wv 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy antiword 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-core 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-java-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-writer 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-calc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-impress 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-pdfimport 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libreoffice-script-provider-bsh 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy openoffice.org-dtd-officedocument1.0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy uno-libs3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy ure 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy unoconv 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-uno 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-urlgrabber 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-urwid 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-utidylib 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-utmp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-van.pydeb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-venusian 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libvigraimpex-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-vigra 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-virtualenv 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-vobject 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-webdav 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-weberror 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-webhelpers 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-webtest 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-webunit 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-werkzeug 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-whisper 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-whoosh 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-wsgi-intercept 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-wtforms 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libwxbase2.8-0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libwxbase2.8-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libwxgtk2.8-0 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libwxgtk2.8-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy wx-common 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy wx2.8-headers 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy wx2.8-i18n 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-wxgtk2.8 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-wxtools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-wxversion 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libxapian-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libxapian22 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xapian-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xapian-omega 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xapian 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xappy 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xattr 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy liblzma-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xzdec 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy xdelta3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xdelta3 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xlrd 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xlwt 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xmlmarshaller 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xmlrunner 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-xmpp 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-yaml 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-yapgvb 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-yenc 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libzbar-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libzbar0 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  8th ~100 core, VireoMD-standard VAOS packages installed:  2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy zbar-tools 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-zbar 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-zmq 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy python-zmq-dbg 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyvnc2swf 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy pyxplot 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy libquantlib0-dev 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get install -qqy quantlib-python 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  End install of all core, VireoMD-standard VAOS packages here:  2>&1 | tee -a $VAOS_BOOT_LOG
set +x
#
### Configure core virtual appliance operating system (VAOS) packages
#
### Configure OS run-time settings (to VireoMD-standards)
#
# Customize /etc/skel (esp. for commands like adduser, useradd, etc.)
#
set -x
BASHRC_FILE="/etc/skel/.bashrc"
which emacs
if [ $? = "0" ]; then
    fgrep -i EDITOR $BASHRC_FILE
    if [ $? != "0" ]; then
        echo INFO:  Setting default /etc/skel editor to emacs in $BASHRC_FILE 2>&1 | tee -a $HOS_BOOT_LOG
        if [ -d /usr/bin/emacs ]; then
            EMACS_EXE="/usr/bin/emacs"
        else
            EMACS_EXE=`which emacs`
        fi
        echo " " >> $BASHRC_FILE
        echo "# 20130105 SCH  Set default editor to emacs" >> $BASHRC_FILE
        echo "export EDITOR=$EMACS_EXE" >> $BASHRC_FILE
        echo " " >> $BASHRC_FILE
    else
        echo INFO:  Default /etc/skel editor already in $BASHRC_FILE.  Skipping ... 2>&1 | tee -a $HOS_BOOT_LOG
    fi
else
    echo WARNING:  emacs executable not found, so $BASHRC_FILE left as is ... 2>&1 | tee -a $HOS_BOOT_LOG
fi
unset BASHRC_FILE
# Make emacs the default editor for the existing (and first) vmdadmin user account
BASHRC_FILE="/home/vmdadmin/.bashrc"
which emacs
if [ $? = "0" ]; then
    fgrep -i EDITOR $BASHRC_FILE
    if [ $? != "0" ]; then
        echo INFO:  Setting vmdadmin default editor to emacs in $BASHRC_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
        if [ -d /usr/bin/emacs ]; then
            EMACS_EXE="/usr/bin/emacs"
        else
            EMACS_EXE=`which emacs`
        fi
        echo " " >> $BASHRC_FILE
        echo "# 20130105 SCH  Set default editor to emacs" >> $BASHRC_FILE
        echo "export EDITOR=$EMACS_EXE" >> $BASHRC_FILE
        echo " " >> $BASHRC_FILE
        unset EMACS_EXE
    else
        echo INFO:  Default editor already in $BASHRC_FILE.  Skipping ... 2>&1 | tee -a $VAOS_BOOT_LOG
    fi
else
    echo WARNING:  emacs executable not found 2>&1 | tee -a $VAOS_BOOT_LOG
fi
unset BASHRC_FILE
# Recall that the ssh server (sshd) was configured above.  openssh-server is 
# a special accessibility package - so it gets installed AND configured 
# ahead of all core packages.  Here, configure the defaults for all locally 
# run ssh clients.  Make all local ssh clients try to keep their ssh 
# connections alive (using the SSH v2 protocol's noop messages to fool
# nosy routers/firewalls/etc.).
SSH_CFG_FILE="/etc/ssh/ssh_config"
fgrep -i ServerAliveInterval $SSH_CFG_FILE
if [ $? != "0" ]; then
    fgrep -i ServerAliveCountMax $SSH_CFG_FILE 
    if [ $? != "0" ]; then
        echo INFO:  Setting ServerAlive* directives in $SSH_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG  
        echo " " >> $SSH_CFG_FILE
        echo "# 20130103 SCH  Try to keep all local ssh client connections alive" >> $SSH_CFG_FILE
        echo "ServerAliveInterval 240" >> $SSH_CFG_FILE
        echo "ServerAliveCountMax 10" >> $SSH_CFG_FILE
        echo " " >> $SSH_CFG_FILE
    else
        echo INFO:  Skipping reset of ServerAlive* directives in $SSH_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
    fi
else
    echo INFO:  Skipping override of any ServerAlive* directives in $SSH_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
fi
echo INFO:  Dump of $SSH_CFG_FILE starts here: 2>&1 | tee -a $VAOS_BOOT_LOG
cat $SSH_CFG_FILE 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  Dump of $SSH_CFG_FILE ends here: 2>&1 | tee -a $VAOS_BOOT_LOG
unset SSH_CFG_FILE
set +x
#
### Install python pkgs/facilities NOT packaged/supported by Canonical/Ubuntu
#
set -x
# Plugins: Python Component Architecture (PCA) and yapsy. One of 
# these will be used by VireoMD's recursive operations centers (ROCs) - and
# in particular - by the ROC facilitated 'prov' (or provisioning) job. 
echo INFO:  easy_install PyUtilib starts here:  2>&1 | tee -a $VAOS_BOOT_LOG
easy_install PyUtilib 2>&1 | tee -a $VAOS_BOOT_LOG
# Be sure to get the version of yapsy prior to the switch to Python 3
# (for Ubuntu 12.04)
echo INFO:  easy_install yapsy starts here:  2>&1 | tee -a $VAOS_BOOT_LOG
easy_install yapsy==1.8 2>&1 | tee -a $VAOS_BOOT_LOG
set +x
#
#
###  Clean up
#
set -x
# Just to be sure everything is up to snuff (but this often does nothing)
echo INFO:  apt-get update -qqy start now: 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get update -qqy 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  apt-get upgrade -qqy start now: 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get upgrade -qqy 2>&1 | tee -a $VAOS_BOOT_LOG
echo INFO:  apt-get autoremove -qqy start now: 2>&1 | tee -a $VAOS_BOOT_LOG
apt-get autoremove -qqy 2>&1 | tee -a $VAOS_BOOT_LOG
set +x
###  Optional, best effort work
#
set -x
# 20130110 SCH  NEVER do the following apt-get install for git-el. 
#               This seems to crash the guest OS.  Whatever it,
#               does it triggers openssh-server to terminate 
#               all existing sessions and to hang any new 
#               session/connection attempts.  See known bug above.
#               This was tried both in the core package install 
#               list and here at the very end of the firstboot
#               script.  Just run this manually (if you need it).
#               NEVER uncomment the following line!
# apt-get install -qqy git-el 2>&1 | tee -a $VAOS_BOOT_LOG
#
set +x
###  Open to VireoMD's recursive operations center (ROC) tree, see FD above
#
set -x
echo INFO:  vaos_boot.sh run ends here:  2>&1 | tee -a $VAOS_BOOT_LOG
echo " " 2>&1 | tee -a $VAOS_BOOT_LOG
set +x

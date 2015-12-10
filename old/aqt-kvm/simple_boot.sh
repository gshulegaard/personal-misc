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
#passwd -e vmdadmin 2>&1 | tee -a $VAOS_BOOT_LOG
#adduser vmdadmin www-data 2>&1 | tee -a $VAOS_BOOT_LOG
# ... and just to be double sure ...
#adduser vmdadmin sudo 2>&1 | tee -a $VAOS_BOOT_LOG
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
#(su -l vmdadmin -c "ssh-keygen -t rsa -N \"\" -f /home/vmdadmin/.ssh/id_rsa") 2>&1 | tee -a $VAOS_BOOT_LOG
#if [ -d /home/vmdadmin/.ssh ]; then
#    echo INFO:  Excellent.  ssh-keygen worked as expected for vmdadmin.  2>&1 | tee -a $VAOS_BOOT_LOG
#    ls -ld /home/vmdadmin 2>&1 | tee -a $VAOS_BOOT_LOG
#else
#    echo INFO:  Weird, but ssh-keygen did not seem to work for vmdadmin.  Forging ahead.  No worries.  2>&1 | tee -a $VAOS_BOOT_LOG
#    mkdir /home/vmdadmin/.ssh 2>&1 | tee -a $VAOS_BOOT_LOG
#    chown vmdadmin:vmdadmin /home/vmdadmin/.ssh 2>&1 | tee -a $VAOS_BOOT_LOG
#    chmod 700 /home/vmdadmin/.ssh 2>&1 | tee -a $VAOS_BOOT_LOG
#fi
# One way or another, the /home/vmdadmin/.ssh directory should now exist!
#if [ -d /home/vmdadmin/.ssh ]; then
#    if [ -f /root/vmdadmin_at_kvm_host_id_rsa.pub ]; then
#        echo INFO:  Copy vmdadmin@kvm-host id_rsa.pub to local vmdadmin authorized_keys file 2>&1 | tee -a $VAOS_BOOT_LOG
#        (cat /root/vmdadmin_at_kvm_host_id_rsa.pub >> /home/vmdadmin/.ssh/authorized_keys) 2>&1 | tee -a $VAOS_BOOT_LOG
#    else
#        echo INFO:  No vmdadmin@kvm-host id_rsa.pub file found.  Ignore omission  2>&1 | tee -a $VAOS_BOOT_LOG
#    fi
#    if [ -f /root/schulegaard_at_kvm_host_id_rsa.pub ]; then
#        echo INFO:  Copy schulegaard@kvm-host id_rsa.pub to local vmdadmin authorized_keys file 2>&1 | tee -a $VAOS_BOOT_LOG
#        (cat /root/schulegaard_at_kvm_host_id_rsa.pub >> /home/vmdadmin/.ssh/authorized_keys) 2>&1 | tee -a $VAOS_BOOT_LOG
#    else
#        echo INFO:  No schulegaard@kvm-host id_rsa.pub file found.  Ignore omission  2>&1 | tee -a $VAOS_BOOT_LOG
#    fi
#    if [ -f /home/vmdadmin/.ssh/authorized_keys ]; then
#        chown vmdadmin:vmdadmin /home/vmdadmin/.ssh/authorized_keys 2>&1 | tee -a $VAOS_BOOT_LOG
#        chmod 600 /home/vmdadmin/.ssh/authorized_keys 2>&1 | tee -a $VAOS_BOOT_LOG
#    fi
#else
#    echo "EXCEPT:  Trouble creating /home/vmdadmin/.ssh directory.  Skipping, but how did this happen?" 2>&1 | tee -a $VAOS_BOOT_LOG
#fi
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

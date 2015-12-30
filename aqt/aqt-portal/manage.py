#! python

__author__     = "Grant Hulegaard"
__copyright__  = "Copyright 2015, AQT Solutions"
__credits__    = ["Grant Hulegaard"]
__license__    = ""
__version__    = "2.1.0" # Major.Minor.Patch-Build
__maintainer__ = "Grant Hulegaard"
__email__      = "hulegaardg@aqtsolutions.com"
__status__     = "Production"

"""
manage.py: 

AQT Solutions management utility for completing installation and conducting
other administrative tasks on AQT Portal stack after applying the the .deb
package.

By default this script is placed in /var/local/aqt-portal/.
"""

import sys
import os
import subprocess


#
# Management functions
#


def install():
    """
    Initial installation function.  This function installs requirements and
    configures the system to run the AQT Portal web application.
    """

    # ngportal
    print "Attempting ngportal configuration...",

    try:
        subprocess.check_call(
            "chown root:www-data -R /var/local/aqt-portal/html",
            shell=True
        )

        subprocess.check_call(
            "chmod u=rwx,g=rwx,o=r -R /var/local/aqt-portal/html",
            shell=True
        )

        subprocess.call(
            "rm /etc/nginx/sites-enabled/*",
            shell=True
        )

        subprocess.check_call(
            (
                "ln -s /etc/nginx/sites-available/aqt-portal " + 
                "/etc/nginx/sites-enabled/aqt-portal"
            ),
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem configuring the SPA."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)

    # atms-api
    print "Installing API...",

    try:
        subprocess.check_call(
            "easy_install *.tar.gz",
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem installing Pyramid API into Python environment."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)

    # guacd
    print "Compile and install of guacd...",
    try:
        # Install dependencies.
        subprocess.check_call(
            (
                "apt-get install " + 
                "libcairo2-dev " + 
                "libpng12-dev " + 
                "libossp-uuid-dev " +
                "libfreerdp-dev " + 
                "libpango1.0-dev " + 
                "libssh2-1-dev " + 
                "libtelnet-dev " + 
                "libvncserver-dev " + 
                "libpulse-dev " + 
                "libssl-dev " +
                "libvorbis-dev"
            ),
            shell=True
        )

        # Build source code.
        subprocess.check_call(
            (
                "cd /var/local/aqt-guacamole-server-* " +
                "&& " +
                "./configure --with-init-dir=/etc/init.d"
            ),
            shell=True
        )

        # Compile with make.
        subprocess.check_call(
            (
                "cd /var/local/aqt-guacamole-server-* " +
                "&& " +
                "make"
            ),
            shell=True
        )

        # Install with make.
        subprocess.check_call(
            (
                "cd /var/local/aqt-guacamole-server-* " +
                "&& " +
                "make install"
            ),
            shell=True
        )

        # Not sure what this does...
        subprocess.check_call(
            (
                "cd /var/local/aqt-guacamole-server-* " +
                "&& " +
                "ldconfig"
            ),
            shell=True
        )

        # Enable sound and drive/printer sharing.
        subprocess.check_call(
            "ln -s /usr/local/lib/freerdp/*.so /usr/lib/x86_64-linux-gnu/freerdp/",            
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem installing guacamole-server."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)


def start():
    """
    Function that starts all pieces of the AQT Portal web application.  Intended
    to be called from /etc/rc.local.

    Since this function is designed to support being called by /etc/rc.local, it
    must not take user input and must not rely on system paths.
    """

    # nginx
    print "Starting nginx...",

    try:
        subprocess.check_call(
            "service nginx start",
            shell=True
        )

        subprocess.check_call(
            "service nginx restart",
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem starting nginx."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)

    # atms-api
    print "Starting atms-api...",

    try:
        # Kill all other active uwsgi processes.
        subprocess.call(
            (
                "ps -elf | fgrep uwsgi | awk '{print $4}' | xargs kill"
            ),
            shell=True
        )

        # Start a new uwsgi process.
        subprocess.check_call(
            (
                "uwsgi --http :8000 -w atms_api:app --daemonize " +
                "/var/local/aqt-portal/log/uwsgi.log"
            ),
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem starting atms-api."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)

    # Apache Tomcat (guacamole-skeleton-java)
    print "Starting Apache Tomcat...",

    try:
        subprocess.check_call(
            "/var/local/apache-tomcat-8.0.20/bin/shutdown.sh",
            shell=True
        )

        subprocess.check_call(
            "/var/local/apache-tomcat-8.0.20/bin/startup.sh",
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem starting Tomcat."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)

    # guacd
    print "Starting guacd...",

    try:
        # Can also be called with...
        # /etc/init.d/guacd start
        subprocess.check_call(
            "service guacd start",
            shell=True
        )

        subprocess.check_call(
            "service guacd restart",
            shell=True
        )
    except:
        status = "FAIL"
        message = "Error: Problem starting guacd."
    else:
        status = "Success"
        message = ""
    finally:
        print status

        if status == "FAIL":
            print message + "\n"
            print "Exit with status 1\n"
            # Exit with system status '1' (failure).
            sys.exit(1)


#
# Main processing
#

# Catch command line action
try:
    action = sys.argv[1]
except IndexError:
    print "Error: No action specified."
    # Exit with system status '1' (failure).
    sys.exit(1)

# Launch processing based on action sent.
if action == "install":
    print "Beginning initial install process..."
    install()

elif action == "start":
    print "Starting aqt-portal..."
    start()

else:
    # Action was not recognized.
    print (
        "Error: Unrecognized action '" + 
        action +
        "'."
    )
    # Exit with system status '1' (failure).
    sys.exit(1)

# If functions haven't exited script yet, assume success.
sys.exit()

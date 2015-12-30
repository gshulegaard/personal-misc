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
build.py: 

AQT Solutions build utility for building the AQT Portal .deb package.
"""

import sys
import os
import subprocess


#
# Catch command line arguments.
#


try:
    name = sys.argv[1]
except IndexError:
    print "Error: No package name was specified."
    # Exit with system status '1' (failure).
    sys.exit(1)
else:
    print "Starting build of package " + name + "..."

# Create target build path.
target = os.path.join("dist", name)


#
# Warning prompt...
#


message = (
    "WARNING:\n" +
    "\n" +
    "You are about to run an automated script that collects resources and\n" +
    "creates a .deb package for redistribution.  This script COLLECTS ONLY.\n" +
    "This means that you should BUILD BEFORE running this collection script."
)

print ""
print message
print ""

response = raw_input("Are you sure you want to proceed? [Y/n]: ")

if (response != "" and
    response != "y" and
    response != "Y"):
    print "Aborting build."
    print ""
    # Exit with system status '1' (failure).
    sys.exit(1)


#
# Start
#


print ""
print "---"
print "Temporary files being written to " + target + "..."
print "Output target is " + target + ".deb..."

print "---"
print ""


#
# Create directory structure
#


# Create package directory...

print "Creating " + target + " directory...",

try:
    subprocess.check_call("mkdir -p " + target, shell=True)
except:
    status  = "FAIL"
    message = "Error: Could not create temporary directory at " + target + "."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)

# Create sub directories...

print "Creating package structure...",

try:
    # /DEBIAN
    subprocess.check_call("mkdir -p " + target + "/DEBIAN", shell=True)

    # /etc/aqt-portal
    subprocess.check_call(
        "mkdir -p " + target + "/etc/aqt-portal",
        shell=True
    )    

    # /etc/nginx/sites-available
    subprocess.check_call(
        "mkdir -p " + target + "/etc/nginx/sites-available",
        shell=True
    )

    # /var/local/aqt-portal
    subprocess.check_call(
        "mkdir -p " + target + "/var/local/aqt-portal",
        shell=True
    )

    # /var/local/aqt-portal/log
    subprocess.check_call(
        "mkdir -p " + target + "/var/local/aqt-portal/log",
        shell=True
    )

    # /var/local/aqt-portal/virtual-drive
    subprocess.check_call(
        "mkdir -p " + target + "/var/local/aqt-portal/virtual-drive",
        shell=True
    )

    # /var/local/aqt-portal/virtualenv
    subprocess.check_call(
        "mkdir -p " + target + "/var/local/aqt-portal/virtualenv",
        shell=True
    )

    # /var/local/aqt-portal/html
    subprocess.check_call("mkdir -p " + target + "/var/local/aqt-portal/html", shell=True)

    # /var/local/aqt-portal/html/build
    subprocess.check_call("mkdir -p " + target + "/var/local/aqt-portal/html/build", shell=True)

    # /var/local/aqt-portal/html/partials
    subprocess.check_call("mkdir -p " + target + "/var/local/aqt-portal/html/partials", shell=True)

    # /var/local/aqt-portal/html/assets
    subprocess.check_call("mkdir -p " + target + "/var/local/aqt-portal/html/assets", shell=True)
except:
    status  = "FAIL"
    message = "Error: Problem creating temporary directory structure."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


#
# Gather resources
#


# Supporting resources (DEBIAN/nginx.conf/manage.py)
# (Requires ln -s for nginx .conf)
print "Gathering supporing files...",
try:
    # Copy nginx.conf.
    subprocess.check_call(
        (
            "cp nginx.conf " + 
            target + 
            "/etc/nginx/sites-available/aqt-portal"
        ),
        shell=True
    )

    # Copy manage.py.
    subprocess.check_call(
        (
            "cp manage.py " + 
            target + 
            "/var/local/aqt-portal/"
        ),
        shell=True
    )

    # Copy DEBIAN/control.
    subprocess.check_call(
        (
            "cp control " + 
            target + 
            "/DEBIAN/"
        ),
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem collecting supporting configuration files."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


# ngportal
# (Requires chown and chmod in install.py)
print "Gathering SPA...",

try:
    # Copy index.html.
    subprocess.check_call(
        (
            "cp ngportal/index.html " + 
            target + 
            "/var/local/aqt-portal/html/"
        ),
        shell=True
    )

    # Copy build/portal.min.js to /var/local/aqt-portal/html/build/
    subprocess.check_call(
        (
            "cp ngportal/build/portal.min.js " + 
            target + 
            "/var/local/aqt-portal/html/build/"
        ),
        shell=True
    )

    # Copy assets directory.
    subprocess.check_call(
        (
            "cp -r ngportal/assets " + 
            target + 
            "/var/local/aqt-portal/html/"
        ),
        shell=True
    )

    # Copy vendor directory.
    subprocess.check_call(
        (
            "cp -r ngportal/vendor " + 
            target + 
            "/var/local/aqt-portal/html/"
        ),
        shell=True
    )

    # Copy modules for HTML templates.
    subprocess.check_call(
        (
            "cp -r ngportal/partials " + 
            target + 
            "/var/local/aqt-portal/html/"
        ),
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem copying SPA files from ngportal dir."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


# atms-api
# (Requires easy_install in install.py)
print "Gathering installation files from atms-api...",

try:
    # Copy settings.ini.
    subprocess.check_call(
        (
            "cp atms-api/settings.ini " + 
            target + 
            "/etc/aqt-portal"
        ),
        shell=True
    )

    # Copy redistributable python .tar.gz.
    subprocess.check_call(
        (
            "cp atms-api/dist/*.tar.gz " + 
            target + 
            "/var/local/aqt-portal"
        ),
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem copying api_core files from api_core dir."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


# tunnel 
# (Requires starting in install.py)
print "Gathering tunnel...",

try:
    # Copy Apache Tomcat.
    subprocess.check_call(
        (
            "cp -r tunnel/apache-tomcat-8.0.20 " + 
            target + 
            "/var/local"
        ),
        shell=True
    )

    # Copy guacamole-skeleton-java.war to Tomcat webapps.
    subprocess.check_call(
        (
            "cp tunnel/guacamole-skeleton-java/target/*.war " + 
            target + 
            "/var/local/apache-tomcat-8.0.20/webapps/guacamole-skeleton-java.war"
        ),
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem copying tunnel files."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


# guacd 
# (Requires compile and install in install.py)
print "Gathering guacd...",

try:
    # Copy guacd.
    subprocess.check_call(
        (
            "cp -r guacd/aqt-guacamole-server-0.9.7 " + 
            target + 
            "/var/local/"
        ),
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem copying guacd source files."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


#
# Create .deb
#


print "Building .deb...",

try:
    # Remove all ~ files from the new modules directory.
    subprocess.check_call(
        (
            "find " + 
            target + 
            " -name '*~' -type f -delete"
        ),
        shell=True
    )

    # Build .deb.
    subprocess.check_call(
        "dpkg-deb --build " + target,
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem building .deb."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


#
# Remove temporary directory structure
#


print "Removing temporary files...",

try:
    # Remove temporary directory.
    subprocess.check_call(
        "rm -rf " + target,
        shell=True
    )
except:
    status  = "FAIL"
    message = "Error: Problem removing temporary file store."
else:
    status  = "Success"
    message = ""
finally:
    print status

    if status == "FAIL":
        print message + "\n"
        print "Exit status 1\n"
        # Exit with system status '1' (failure).
        sys.exit(1)


#
# Success
#

print ""
print "Build of " + name + ".deb success."
print ""

print "Exit status 0\n"
sys.exit()

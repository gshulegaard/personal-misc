===========
aqt-tickets
===========

:Authors:
   Grant Hulegaard
:Release:
   0.1.0
:Release-Date:
   03/06/2015
:Last-Edited:
   03/05/2015

This is the master repository for AQT Solution's web ticket system.  The `AQT
Solutions website`_ is a Wordpress powered site.  The web ticket system is a
Django powered interface to **AQT Services** which is a properietary, internal
system built using PowerBuilder and SQL Anywhere.

.. _`AQT Solutions website`: http://www.aqtsolutions.com/

This project is a "rapid-prototype" solution for porting existing website
functionality to a new tech stack with an updated design.  The **`AQT Portal`_**
project is being built using Pyramid and AngularJS, it is likely that **AQT
Tickets** will be moved to this tech stack in the future.

.. _`AQT Portal`: https://github.com/gshulegaard/aqt-portal-v2

Included below are some installation steps:

Clone the Repository
--------------------

Start by cloning the repository::

    $ git clone http://gitlab.aqtsolutions.net/website/aqt-tickets.git

Set up virtual environment
--------------------------

I recommend creating a dedicated directory for storing your virtualenv
environments.  Personally, I store mine in my "Home" directory::

    $ mkdir ~/env
    $ cd ~/env

After you have this directory, create the virtual environment::

    $ virtualenv aqt-tickets

Installing requirements
-----------------------

This repo includes a "requirements.txt".  To install required packages use pip::

    $ pip install -r requirements.txt

If you are using a virtualenv as was suggested previously, make sure you change
your environment source first::

    $ source ~/.env/aqt-website
    (aqt-tickets)$ pip install -r requirements.txt

Setting up the database
-----------------------

First, install PostgreSQL.  My local database user is "postgres" and its
password is "postgres".  To minimize differences, your database instance should
have a user with the same name and password.

After installing your database manager, create a database to be used by Django::

    # For postgres:
    $ sudo -u postgres createdb aqt-tickets

If you have an identical database naming schema, then you should be able to sync
the database::

    (aqt-tickets)$ python manage.py syncdb
    (aqt-tickets)$ python manage.py migrate

Running development server
--------------------------

As is standard with most django projects::

    (aqt-tickets)$ python manage.py runserver



======
Guides
======

Table of Contents
-----------------

#. `Deployment`_
#. `How-To Git`_
#. `How-To Emacs`_
#. `Deprecated`_



==========
Deployment
==========

This section will cover how to deploy the aqt-portal django project to a web
server.  For AQT Solutions, we have decided to use
`nginx`_.

There are many reasons for this, but the primary focus is: *performance*. nginx
is a web server written entirely in C with an emphasis on performance.  Over the
years `Apache`_ has narrowed the performance gap, but
nginx still has an edge (and likely always will because of its implementation in
C).  Even if this proves ultimately untrue in the future, nginx is still the
safe bet at this moment.

#. `Directory structure`_
#. `Install uWSGI`_
#. `Install nginx`_
#. `Run uWSGI in "emperor" mode`_
#. `Run uWSGI at boot`_
#. `Reference`_
#. `Troubleshooting`_

.. _`nginx`: http://nginx.org/en/
.. _`Apache`: http://httpd.apache.org/


Directory structure
-------------------

On a deployment server, there are some directories and directory structures with
which you should be familiar:

- /etc: Contains ``virtualenv`` and ``uwsgi``.
  - ``virtualenv`` contains python virtual environments.
  - ``uwsgi`` contains uwsgi configuration files.
- /opt: Contains our Django projects (git repositories).
- /tmp: Contains our unix file socket(s) that is used for communication between
  uWSGI and nginx.  This socket will be removed when uWSGI is not running.

Server filesystem:
::
     :/etc
       :/virtualenv  # virtualenv configuration files
         :/env  # folder containg virtualenv's
           :/aqt-portal  # aqt-portal virtual environment

       :/uwsgi  # uwsgi configuration files
         :/vassals  # folder containing uwsgi ini files for uwsgi "vassals"
                   # (emperor mode)


     :/opt
       :/aqt-portal  # git repo installed in the /opt directory


     :/tmp
       portal.sock  # File socket to be used for communication between uWSGI
                    # and nginx.  This will be removed when not in use.

This repository should be placed in the ``/opt`` directory of a provisioned
server.

Django project:
::
   ..:/aqt-portal  # git repo root
       :/api  # back-end django application
       :/main  # primary django application that serves emberjs
       :/nginx  <--
       :/portal  # core django project
       :/uwsgi  <--
       manage.py
       README.rst
       requirements.rst

The ``nginx`` and ``uwsgi`` directories are highlighted because they contain
configuration files that are used during deployment.  These files will have to
be edited on a per-server basis.

Configuration files:
::
     ..:/nginx
          nginx.conf
          uwsgi_params

     ..:/uwsgi
          uwsgi.ini

All three of the configuration files included in the ``nginx`` and ``uwsgi``
directories are used during deployment.


Install uWSGI
-------------

uWSGI can be installed using pip::

  $ pip install uwsgi

Test Django:
  ``uwsgi --http :8000 --module portal.wsgi --enable-threads``

  It is worth noting that django creates a .wsgi file by default at project
  creation (``django-admin.py startproject``).  This .wsgi should be included
  alongside the ``settings.py`` file and is called ``wsgi.py``.

  Therefore, the above command should be run from the top-level directory of
  this project (the directory that contains ``manage.py``).


Install nginx
-------------

nginx can be installed as a debian package::

  $ sudo apt-get install nginx
  $ sudo /etc/init.d/nginx start

  ## nginx can be started as a service as well:
  #$ sudo service nginx start

Copy ``/etc/nginx/uwsgi.params`` to the django project::

  $ sudo cp /etc/nginx/uwsgi.params /opt/aqt-portal/nginx/

The default file provided by the git repository should work, so this step may be
skipped.

Create an ``nginx.conf`` in ``/opt/aqt-portal/nginx/``.  An example is provided
below::

  # aqt-portal/nginx.conf
  #
  # This is an nginx .conf file for the aqt-portal django project.

  # the upstream component nginx needs to connect to
  upstream django {
      server unix:///tmp/portal.sock; # for a file
                                      # socket
      # server 127.0.0.1:8001; # for a web port socket (we'll use this
    	   		       # first)
  }

  # configuration of the server
  server {
      # the port your site will be served on
      listen      80;

      # the domain name it will serve for
  --> server_name 10.10.10.135; # substitute your machine's IP address
     			        # or FQDN
      charset     utf-8;

      # max upload size
      client_max_body_size 75M;   # adjust to taste

      location /static {
          alias /opt/aqt-portal/static;  # your Django
	      			         # project's static
				         # files - amend as
				         # required
      }

      # Finally, send all non-media requests to the Django server.
      location / {
          uwsgi_pass  django;
          include     /opt/aqt-portal/nginx/uwsgi_params;  # the
							   # uwsgi_params
						      	   # file you
						      	   # installed
      }
  }

The only value you should have to change is the ``server_name`` attribute and it
is indicated by ``-->`` above.

Symbolically link the ``nginx.conf`` so ``nginx`` can see it::

  $ sudo ln -s /opt/aqt-portal/nginx/nginx.conf /etc/nginx/sites-enabled/aqt-portal_nginx.conf

You will also have to collect static files with ``manage.py``::

  (aqt-portal)$ python manage.py collectstatic

Collecting static files is only required when deploying Django since otherwise
the python webserver can follow the PATH to the module/folder directly from
``settings.py``.  In a deployed scenario, you want the HTTP server (``nginx``)
to server static files to clients, so you have to collect all static files into
a central location that ``nginx`` knows about.

Restart nginx::

  $ sudo /etc/init.d/nginx restart

  ## or use a service call:
  #$ sudo service nginx restart

Make sure nginx has permission to access the django project files::

  $ sudo chown root:www-data -R /opt/aqt-portal
  $ sudo chmod u=rwx,g=rwx,o=r -R /opt/aqt-portal


Run uWSGI in "emperor" mode
---------------------------

Create/edit ``uwsgi.ini`` (located in /aqt-portal/uwsgi/), an example is
below::

  # /aqt-portal/uwsgi/uwsgi.ini file
  [uwsgi]

  # Django-related settings
  # the base directory (full path)
  chdir           = /opt/aqt-portal
  # Django's wsgi file
  module          = portal.wsgi
  # the virtualenv (full path)
  home            = /etc/virtualenv/env/aqt-portal

  # process-related settings
  # master
  master          = true
  # maximum number of worker processes
  processes       = 10
  # the socket (use the full path to be safe
  socket          = /tmp/aqt_site.sock
  # ... with appropriate permissions - may be needed
  chmod-socket    = 666
  # enable python threads
  enable-threads  = true
  # clear environment on exit
  vacuum          = true

Create configuration directories for uWSGI::

  $ sudo mkdir /etc/uwsgi
  $ sudo mkdir /etc/uwsgi/vassals

Symbolically link the uwsgi.ini from aqt-portal into ``/etc/uwsgi/vassals``
(give it a unique name to avoid confusion)::

  $ sudo ln -s /opt/aqt-portal/uwsgi/uwsgi.ini
  /etc/uwsgi/vassals/aqt-portal_uwsgi.ini

Start uWSGI in "Emperor" mode::

  $ sudo uwsgi --emperor /etc/uwsgi/vassals --uid www-data --gid www-data


Run uWSGI at boot
-----------------

Edit ``/etc/rc.local`` and add::

  /usr/local/bin/wsgi --emperor /etc/uwsgi/vassals --uid www-data -gid www-data &

Example::

  #!/bin/sh -e
  #
  # rc.local
  #
  # This script is executed at the end of each multiuser runlevel.
  # Make sure that the script will "exit 0" on success or any other
  # value on error.
  #
  # In order to enable or disable this script just change the execution
  # bits.
  #
  # By default this script does nothing.

  /usr/local/bin/uwsgi --emperor /etc/uwsgi/vassals --uid www-data --gid www-data 
  &

  exit 0


Reference
---------

There is a good tutorial outlining the steps taken above here:

  https://uwsgi.readthedocs.org/en/latest/tutorials/Django_and_nginx.html

It is important to note that a popular alternative to uWSGI is
`gunicorn`_.  gunicorn is especially popular with the
django web framework because it is simple to set-up and use.

Since django has a "lowest common denominator" type approach to frameworks, I am
wary of tools that emphasize "simplicity" over performance and reliability.
uWSGI is a mature implementation of WSGI and is implemented in C, for these
reasons it was chosen over gunicorn which seems to be the latest trend in the
django community.

.. _`gunicorn`: http://gunicorn.org/


Troubleshooting
---------------

Server Recovery:
  If, for some reason, you accidentally change something that breaks the Ubuntu
  server start process you can use Linux "Safe Boot" from the GRUB [#]_ menu to
  recover [#]_.  When editing init scripts as in the `Run uWSGI at boot`_
  section, errors may prevent a successful boot process.

  Choose the option to start an administrative command prompt and you will have
  access to the file system.  By default, this filesystem is mounted as "Read
  only" when using "Safe Boot".  To remount the system as write-enabled, run::

    $ mount -o remount, rw /

  This command will remount the "/" filesystem with "rw" (read-write)
  directives.  At this point, you should be able to edit any config files that
  were saved erroneously to remedy boot issues.


----


.. [#] `GNU GRUB`_ is a multi-boot boot loader that is typically used to allow
       users to dual-boot windows and linux on their personal machines.  For
       servers, it allows for the selection of different boot images including
       (but not limited to): previous kernel versions, boot recovery, MEMTEST+.

       .. _`GNU GRUB`: http://www.gnu.org/software/grub/

.. [#] Ubuntu Server includes boot recovery tools that it automatically
       registers in a packaged GRUB loader.


----


Back to `Deployment`_.

Back to `Table of Contents`_.



==========
How-To Git
==========

Git is a popular open source version control system.  It tracks changes to files
and allows easy management of merging changes in a line-by-line fashion.  This
allows collaborators to contribute to code bases simultaneously.  If two
developers edit the same **line**, then Git will automatically insert a comment
with both changed lines at the location of the conflict in the file so you can
easily resolve conflicts during the merge process.

Like most open source technologies, Git is robust and flexible.  To this end the
`Development`_ section above documents the proper structure for managing
contributions for this project.  This section will document some of the useful
commands of Git.

#. `Configuration`_
#. `Clone`_
#. `Pull`_
#. `Branch`_
#. `Add`_
#. `Commit`_
#. `Merge`_
#. `Push`_


Configuration
-------------

`Getting Started`_

.. _`Getting Started`: http://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup

Git comes with a few configurations options that you will want to customize.
First, lets talk about git configuration layers.  For this tutorial, we will
focus on *local* and *global*.

*Local*: is the default git configuration that git commands alter and refers to
the *repository's* ``.gitconfig`` file.

*Global*: is your current computer's *user's* .gitconfig file.  Alterations to
this config file will be applied at the user account level rather than the
repository level.

For Ubuntu 14.10, here is an example global ``.gitconfig`` (``~/.gitconfig``)::

  [user]
          email = loki.labrys@gmail.com
          name = Grant Hulegaard
  [core]
          editor = emacs

You can set these values from the command line if you prefer::

  $ git config --global user.name "Grant Hulegaard"
  $ git config --global user.email "loki.labrys@gmail.com"
  $ git congig --global core.editor emacs

You can check all the settings that git can find with ``git config --list``::

  $ git config --list
  user.name=Grant Hulegaard
  user.email=loki.labrys@gmail.com
  core.editor=emacs
  ...

You may see keys multiple times since Git will read all the configuration files
it can find (e.g. ``/etc/gitconfig`` and ``~/.gitconfig``, for example).

You can also check what Git thinks a specific key's value is by typing ``git
config user.name``::

  $ git config user.name
  Grant Hulegaard

Here is a list of common git config keys (`Customizing Git`_):

.. _`Customizing Git`: http://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration

user.name:
  The full name of the git user.

user.email:
  The email of the git user.  This email should match your github account's
  email if you wish to be properly identified.

core.editor:
  The editor you would like git to open when calling for a text editor
  (e.g. when editing a commit message).

commit.template:
  If you set this to the path of a file on your system, Git will use that file
  as the default message when you commit.  For instance, suppose you create a
  template at ``~/.gitmessage.txt`` that looks like this::

    subject line

    what happened

    [ticket: X]

push.default:
  This value can be either ``matching`` or ``simple``.  ``matching`` will will
  push local branches to the remote branches that already exist with the same
  name.  ``simple`` only pushes the current branch to the corresponding remote
  branch that ``git pull`` uses to update the current branch.

  It is recommended that you use ``simple``::

    $ git config --global push.default simple

user.signing key:
  If you're making signed annotated tags (as discussed in `Signing Your Work`_),
  setting your GPG signing key as a configuration setting makes things easier::

    $ git config --global user.signingkey <gpg-key-id>

  Now you can sign things with just an option::

    $ git tag -s <tag-name>
    $ git commit -a -S -m "Your commit message"

.. _`Signing Your Work`: http://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work#_signing


Clone
-----

To clone an existing repository you should use ``git clone``::

  $ git clone <repository-url>

For example, to clone this repository::

  $ git clone https://github.com/gshulegaard/aqt-portal


Pull
----

Once you have a repository, you can keep it updated with ``git pull``::

  $ git pull

There are some configuration options that determine which repository/branch and
how to merge ``pull`` requests, but in most cases the default settings should
suffice.


Branch
------

Branches are the core benefit of using git as a source control system.  They can
be manage with ``git branch``::

  $ git branch <new-branch-name>  # Create a new branch locally with.
  $ git push origin <new-branch-name>  # Push a new branch to the parent repository.
  $ git branch -d <branch-name>  # Delete a branch.
  $ git push origin :<branch-name>  # Push the deletion upstream (delete branch
                                    # in the parent repository).

Branching allows developers to easily create, manage, and merge changes of code
forks.


Add
---

Git tracks line-by-line changes to individual files.  To add a file to be
tracked, use ``git add``::

  $ git add <file>

In most cases, you will want to add ``all`` files in a repository directory to
be tracked::

  $ git add --all


Commit
------

When you are at a "save" point, you will want to commit changes to the
repository to easily manage versions and code evolution.  You can do so with
``git commit``::

  $ git commit

This will open an editor dialogue so you may enter a "commit message" to be
displayed to other collaborators viewing your commit.

You can also tell git what the message should be from the command line::

  $ git commit -m "My commit message."

You can also combine commit and add with ``-a``::

  $ git commit -a -m "My commit message."

Finally, if you have configured GPG signing, you can sign the commit with
``-S``::

  $ git commit -a -S -m "My commit message."

Signing is not yet configured for this repository.


Merge
-----

As various forks of the ``master`` branch evolve, you may want to merge changes
between them.  You can easily manage merging with ``git merge``::

  $ git merge <branch>

This command will merge the named "``<branch>``" with your current branch.  For
example if you want to merge "``branch-1``" with a "``branch-2``" you could do::

  $ git checkout branch-1
  $ git merge branch-2

  -or-

  $ git checkout branch-2
  $ git merge branch-1

In the first example, you are merging ``branch-2`` *into* ``branch-1``.  This
means that any conflicts during the merge will be made on ``branch-1``.

In the second example, you are merging ``branch-1`` *into* ``branch-2``.  This
means that any conflicts during the merge will be made on ``branch-2``.

For the proper merging steps for this repository, consult the `Development`_
section of this README.


Push
----

As you develop, commit, and merge you may want to update the remote repository
that other collaborators ``pull`` from.  You can do this ``git push``.

Git push is pretty self-explanatory, but remember that you can only push
branches that exist on the remote parent repository.  See `Branch`_ for more
information.

Setting the upstream of a branch:
  When you create branches that you have pushed upstream (see `Branch`_), you
  may have to set your upstream on your first ``git push`` or ``git pull``::

    $ git push --set-upstream origin <upstream-branch>


----


Back to `How-To Git`_.

Back to `Table of Contents`_.



============
How-To Emacs
============

Emacs is a robust text editor (well...more like an operating system) that
supports rich features such as:

- Syntax highlighting
- Multiple window management
- Split windows
- Embedded running embedded ``terminals``
- and much much more...

Emacs is extraordinarily useful since it runs within a shell.  This means that
it can be run in a command line ``ssh`` session.

Due to its advanced functionality and keyboard-only design, Emacs has a fairly
steep learning curve.  To help some and aid others in Ubuntu server
administration, this is a QDRef (Quick and Dirty Reference) of useful Emacs
shortcuts to get even beginners up-and-running.

#. `Basics`_
#. `Files`_
#. `Buffers`_ (windows)
#. `Terminal`_ (ansi-term)

Outside of this tutorial, `GNU Guided Tour of Emacs`_ is another good starting
reference for Emacs.

You may install Emacs on Ubuntu with::

  $ sudo apt-get install emacs24

Depending on your version of Ubuntu, you may want to remove emacs23::

  $ sudo apt-get remove emacs23

.. _`GNU Guided Tour of Emacs`: http://www.gnu.org/software/emacs/tour/


Basics
------

Emacs is designed to run in a shell buffer, so it is therefore also implicitly
designed to run completely from keyboard input.  To make this possible and
provide all of its advanced functionality, Emacs makes heavy use of *keyboard
shortcuts*.  It does this by using an *input pre-processor* to listen for
certain key combinations and escaping to an Emacs "*command-buffer*" when
certain combinations are entered.

These commands come in two flavors: *Shortcuts* and *Invoked Commands*.

Shortcuts are denoted by a "``C-``".  ``C``, by default, is the ``Ctrl`` key on
a keyboard.  So if you see a command ``C-x``, it means hit ``Ctrl`` + ``x``.
The ``C`` key is also called the "*Command*" key.

Invoked commands are typed commands and are denoted by a ``M-``.  ``M``, by
default, is the ``Alt`` key on a keyboard.  So if you see ``M-x``, it means hit
``Alt`` + ``x``.  The ``M`` key is also called the "*Meta*" key.

Key combinations can be combined.  For example::

  C-x C-f:  Ctrl + x, then Ctrl + f (this command will tell emacs to open a file)

  M-x rename-buffer:  Alt + x, then type "rename-buffer" (this invoked command
                      will tell emacs to rename the current buffer to whatever
                      you type.)

It is pertinant to note that ``M-x`` commands cannot have spaces (they will
always be separated by dashes).  Emacs will automatically replace ``<space>``
with a ''-'' when writting in the command buffer.

To open emacs::

  $ emacs -nw

-nw           Stands for "new window" and will tell emacs to open in a new
              window.

The ``-nw`` option is optional and emacs may be started with a simlple ``$
emacs`` command-line if desired.

To close emacs::

  C-x C-c

  ## Alternatively, you can use the invoked command instead:
  M-x kill-emacs

If you ever enter accidental Emacs key strokes into the command buffer, you can
clear it quickly with ``C-g`` a couple of times.  E.g.::

  C-g C-g C-g


Files
-----

There are two ways to open files with Emacs.

You can open it from the command line with::

  $ emacs [filename]

Where ``[filename]`` is a path to a particular file.  This command will open an
Emacs session and open a buffer with the file in it at start.

You can also open any file from within emacs with::

  C-x C-f

This will start the "Find file:" command in the Emacs command buffer.  From this
buffer you can type the name of any file in the current working directory.  You
can traverse the file system like you would normally do from the command line by
simply typing a folder's name.  Alternatively, you can back trace from the
current working directory by entering "``..``".

Emacs keeps track of its current working directory from a) the terminal it was
spawned in or b) the currently active terminal session.  A) is determined by the
directory in which you ran the ``emacs`` command from.  B) relates to the
`Terminal`_ section.

Finally, you can ``save`` files with::

  C-x s

This will open a prompt, you can skip the prompt and ``automatically save``
with::

  C-x C-s

You can also ``save as`` with::

  C-x C-w


Buffers
-------

The most basic way of conceptualizing buffers is by opening the Emacs ``*Buffer
List*``::

  C-x C-b

This list will show you all active/open buffers within your Emacs session.

You can also rapidly switch between buffers with::

  C-x b [buffer name]

If you don't enter a ``[buffer name]`` Emacs will switch to your last used
buffer.

One of the most useful features of Emacs buffers is that you can have multiple
buffers open at once (much like having multiple windows open).  Here are some
useful commands for opening and managing windows::

  C-x 2  # Horizontally splits your current buffer.
  C-x 3  # Vertically splits your current buffer.
  C-x o  # Switch your current active buffer to the next one in the rotation.
  C-x 0  # Hides your current window, but doesn't kill the buffer.

These commands can be nested.  For example::

  C-x 3, C-x o, C-x 2

Will first split your main window vertically in half, leaving you with two
equally sized windows side-by-side.  Then, it will switch your currently active
buffer from the left window (original) to the right window (new).  Finally, the
last command will split the right window (the now active window) in half
horizontally.  This makes Emacs emulate the layout of popular IDEs where there
is a primary code area to the left, a file or object explorer in the upper
right, and a terminal/debugger in the lower right.

Emacs buffers and windows are flexible so you should experiment with them to
find out how you like working best.


Terminal
--------

There are a number of ways to open a terminal in an Emacs buffer.  But by far
the most robust is ``ansi-term``.

You can open an ``ansi-term`` buffer with::

  M-x ansi-term

``ansi-term`` by default runs in "Character mode" which disables the Emacs input
pre-processor so all key combinations are sent directly to the instance of the
bash shell.  This means that most of your Emacs shortcuts will not work in an
``ansi-term`` buffer.

You can switch to "Line mode" with::

  C-c C-j

And then switch back to "Character mode" with::

  C-c C-k

So you can temproarily enable Emacs shortcuts.  I commonly do this to rename my
``ansi-term`` buffers into something more descriptive::

  C-c C-j  # Switch to Line Mode.
  M-x rename-buffer [new name]  # Change the name of the buffer.
  C-c C-k  # Switch back to Character Mode to resume regular terminal behavior.


----


Back to `How-To Emacs`_.

Back to `Table of Contents`_.


==========
Deprecated
==========

#. `Troubleshooting pyodbc`_


Troubleshooting pyodbc
----------------------

Troubleshooting: pyodbc
  https://snakeycode.wordpress.com/2013/12/04/installing-pyodbc-on-ubuntu-12-04-64-bit/
  http://www.pauldeden.com/2008/12/how-to-setup-pyodbc-to-connect-to-mssql.html

  pyodbc is a mature and actively maintained python package, but it does have some
  installation nuances that prevent traditional "simple" ''pip'' installation.  In
  most cases, this will cause problems when installing from the
  ''requirements.txt'' for the first time.

  First, install some dependencies::

    $ sudo apt-get install unixodbc unixodbc-dev freetds-dev freetds-bin tdsodbc

  Next, edit ''/etc/odbcinst.ini'' by adding the following block (note that the
  file is likely empty before this)::

    [FreeTDS]
    Description=FreeTDS Driver
    Driver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
    Setup=/usr/lib/x86_64-linux-gnu/odbc/libtdsS.so

  Now you should be able to install pyodbc::

    $ pip install pyodbc

  If this is successful, then you should be able to install the rest of the
  requirements::

    $ pip install -r requirements.txt


----


Back to `Deprecated`_.

Back to `Table of Contents`_.

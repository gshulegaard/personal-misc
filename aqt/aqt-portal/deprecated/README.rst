=============
aqt-portal-v2
=============

:Authors:
   Grant Hulegaard
:Developers:
   Grant Hulegaard,
   Matthew Fay
:Release:
   0.2.0
:Release-Date:
   02/15/2015
:Last-Edited:
   01/30/2015

This is the master project repository for AQT Solutions' ATMS *Portal*
*v0.2.x*.  This README is intended for Developer use and represents a
comprehensive basic introduction to this repository and practices.

This README aims to be an exhaustive reference for aqt-portal *v0.2.x* until a
more robust documentation system can be put in place.


Version 0.2.0:
  This project is a ground-up redesign of aqt-portal (version(s) *0.1.x*).

  *0.1.x* was a complete proof of concept, but there were some lessons learned
  from that prototype that are resulting in some core changes to the stack.
  Because of the fundamental nature of these changes, a complete rewrite is
  warranted, hence version *0.2.0* is being forked into it's own repository.


----


Footnotes:
  Footnotes denoted by ``[#]`` will be included at the bottom of the section
  they are referenced in.  For example there is a footnote section at the bottom
  of "Installation".


Table of Contents
-----------------

#. `Installation`_
#. `Deployment`_
#. `Development`_
#. `How-To Git`_
#. `How-To Emacs`_
#. `How-To Pyramid`_
#. `How-To Cornice`_
#. `Deprecated`_



============
Installation
============

This section will outline the steps required to perform a fresh installation of
this project.  This guide is comprehensive and does not assume anything other
than you are using Ubuntu 14.10.

#. `Clone the repository`_
#. `Set up the virtual environment`_
#. `Install pyramid`_
#. `Installing requirements`_
#. `Running the development server`_


Clone the repository
--------------------

Start by cloning [#]_ the repository::

  $ git clone https://github.com/gshulegaard/aqt-portal


Set up the virtual environment
------------------------------

It is recommended that you create a dedicated directory for storing your
virtualenv environments.  This is, however, not required and may be skipped::

  $ mkdir ~/.env
  $ cd ~/.env

You may then create a new virtual environment [#]_::

  $ virtualenv aqt-portal-v2


Install pyramid
---------------

See `Pyramid Tutorial`_ for reference.

.. _`Pyramid Tutorial`: http://docs.pylonsproject.org/projects/pyramid/en/latest/quick_tutorial/requirements.html

Pyramid uses ``easy_install`` rather than ``pip`` [#]_.  To account for this, you
should install ``pyramid`` before installing the requirements from the
``requirements.txt``::

  (aqt-portal-v2)$ easy_install "pyramid==1.5.2"

This will install ``pyramid`` and a variety of dependencies automatically.


Installing requirements
-----------------------

This repo includes a "requirements.txt".  To install required packages use
pip::

  (aqt-portal-v2)$ pip install -r requirements.txt

Note:
  If you are using a virtual environment, like it is suggested above, then you
  should first make sure that you are using the appropriate virtual environment
  "source"::

    $ source ~/.env/aqt-portal-v2/bin/activate
    (aqt-portal-v2)$ pip install -r requirements.txt

Troubleshooting pymssql:
  http://ozzieeu.blogspot.com/2014/02/troubleshooting-pymssql-installation-on.html

  Pymssql seems to be a relatively stable and complete MSSQL driver for python.
  We have chosen to use it because, simply, *it works*.  It does, however,
  require ``freetds-dev`` and possibly ``python-dev``.  You can install both
  with apt-get::

    $ sudo apt-get install freetds-dev python-dev

  Afterwards, you should be able to install ``pymssql`` via ``pip``::

    (aqt-portal)$ pip install pymssql


Running the development server
------------------------------

There are two ways to run ``pyramid`` applications in development.  The first
(and more basic) method is to define the web server in a ``python`` script like
this example ``app.py``::

  from wsgiref.simple_server import make_server
  from pyramid.config import Configurator
  from pyramid.response import Response


  def hello_world(request):
    print('Incoming request')
    return Response('<body><h1>Hello World!</h1></body>')


  if __name__ == '__main__':
    config = Configurator()
    config.add_route('hello', '/')
    config.add_view(hello_world, route_name='hello')
    app = config.make_wsgi_app()
    server = make_server('0.0.0.0', 6543, app)
    server.serve_forever()

Since a developmental server is defined in the runtime using
``wsgiref.simple_server``, we can just run ``app.py`` as a python application::

  (aqt-portal-v2)$ python app.py

The second, more advanced, method for running a development server is via
``pserve`` using an ``ini`` file.  To do this you must first refactor your
``pyramid`` application as a package.

After refactoring into a package, an example ``ini`` file would be::

  [app:main]
  use = egg:tutorial

  [server:main]
  use = egg:pyramid#wsgiref
  host = 0.0.0.0
  port = 6543

We can then refactor ``app.py`` from before into an ``__init__.py__`` for the
application package::

  from pyramid.config import Configurator
  from pyramid.response import Response


  def hello_world(request):
    return Response('<body><h1>Hello World!</h1></body>')


  def main(global_config, **settings):
    config = Configurator(settings=settings)
    config.add_route('hello', '/')
    config.add_view(hello_world, route_name='hello')
    return config.make_wsgi_app()

Now you can start the ``pyramid`` application with ``pserve``::

  (aqt-portal-v2)$ pserve example.ini --reload


----


.. [#] This project uses git for version control.  Install git with ``sudo
       apt-get install git``.

.. [#] virtualenv is a python virtualization tool that cretes "sandboxed" python
       executable environments.  To install, run ``sudo apt-get install
       virtualenv``.

.. [#] Why ``easy_install`` and not ``pip``? Pyramid encourages use of namespace
       packages, for which ``pip``'s support is less-than-optimal. Also,
       Pyramid's dependencies use some optional ``C`` extensions for
       performance: with ``easy_install``, Windows users can get these
       extensions without needing a ``C`` compiler (``pip`` does not support
       installing binary Windows distributions, except for ``wheels``, which are
       not yet available for all dependencies).


----


Back to `Installation`_.

Back to `Table of Contents`_.



==========
Deployment
==========


----


Back to `Deployment`_.

Back to `Table of Contents`_.



===========
Development
===========

This section will go over how to properly contribute to this repository using
git.  This guide will cover a step-by-step process for creating and merging
branches to the primary upstream process.

If you are new to git, it is recommended that you read `How-To Git`_ as a primer
before continuing.  `How-To Git`_ is a higher level overview of Git whereas this
guide contains detailed instructions for how to properly checkout and merge
changes to the upstream control repository.


Steps:
------

#. `Create new branch`_
#. `Push branch to master`_ (optional)
#. `Merge master with branch`_
#. `Merge branch with master`_
#. `Push changes upstream`_
#. `Delete branch`_


Create new branch
-----------------

The first thing to do is to create a new repository branch.  To create a new
branch locally::

  $ git checkout -b newbranch

There are a couple of things to note here.

First, ``newbranch`` is the name of your new branch.  This can be whatever you
would like, so a descriptive name is best to prevent confusion.  For example, if
I wanted to create a new branch to update the login screen of the portal, I
might call it ``login-redesign``.

Second, the ``-b`` option actually turns the git ``checkout`` command into two,
combined, commands.  Using ``git checkout -b`` is the same as::

  $ git branch newbranch
  $ git checkout newbranch

Basically, it creates a new branch and then switches your working branch to that
branch automatically.


Push branch to master
---------------------

At this point you have only created a new branch locally.  This means that other
users of the repository will **not** be able to access your branch.  In some
cases this is desirable, so pushing the branch upstream is *optional*.

If you are working on a branch that requires collaboration, then you can push a
branch upstream with::

  $ git push origin newbranch


Merge master with branch
------------------------

Once you have completed work (after ``git commit``), you will want to merge your
changes to the "master" repository.  To do this (and prevent conflicts) you will
first merge "master" with your branch, resolve conflicts (if any), and finally
merge with master.

To start, make sure you have the latest version of the master::

  $ git checkout master
  $ git pull

Next, merge master with your branch (make **sure** you are running merge from
your branch and not master)::

  $ git checkout newbranch
  $ git merge master

The ``git merge`` command will merge the named repository (in this case
``master``) *with your current working branch* (in this case ``newbranch``).

After resolving conflicts, if any, you may then `Merge branch with master`_.


Merge branch with master
------------------------

::

  $ git checkout master
  $ git pull  # Not required, but good practice.  If there are changes repeat
              # above merging and conflict resolution before proceeding.
  $ git merge newbranch

If your ``git pull`` pulls down changes, repeat `Merge master with branch`_.

If you have been merging down to your branch first as outlined above, you should
not have any conflicts when merging with master.


Push changes upstream
---------------------

Now that your master has been updated, you can push the changes upstream::

  $ git checkout master
  $ git push


Delete branch
-------------

Now that ``newbranch`` has been merged with master, it may no longer be
neccessary to keep around.  To delete the branch::

  $ git checkout master
  $ git branch -d newbranch
  $ git push origin :newbranch

``git branch -d`` deletes the branch locally, ``git push origin :newbranch``
pushes the deletion up to github.


----


Back to `Development`_.

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



==============
How-To Pyramid
==============

This ``How-To`` is based off of the ``pyramid`` `Quick Tutorial`_.

.. _`Quick Tutorial`: http://docs.pylonsproject.org/projects/pyramid/en/latest/quick_tutorial/index.html

#. `Install`_
#. `Start project`_ (pcreate & pserve)
#. `Install cornice`_ (cornice)
#. `Install jinja2`_ (jinja2 templates)


Install
-------

``pyramid`` uses ``easy_install`` rather than ``pip`` packaging [#]_.  You
should still be using environment virtualization.  This is either ``virtualenv``
for ``python2`` or the ``python3`` new ``venv`` module.

For ``virtualenv``:
  ::
     $ virtualenv ~/.env/aqt-portal-v2
     $ source ~/.env/aqt-portal-v2
     (aqt-portal-v2)$ ...

``venv`` instructions are not included at this time.

After virtualization, you can install ``pyramid``::

  (aqt-portal-v2)$ easy_install "pyramid==1.5.2"

This command will automatically install ``pyramid`` and a number of its
dependencies.

After installation you can check the available ``pcreate`` scaffolds::

  (aqt-portal-v2)$ pcreate --list
  Available scaffolds:
    alchemy:                Pyramid SQLAlchemy project using url dispatch
    starter:                Pyramid starter project
    zodb:                   Pyramid ZODB project using traversal

Note:
  If you plan on using the ``alchemy`` scaffold, you should probably install
  ``SQL Alchemy``::
  
    $ pip install sqlalchemy


Start project
-------------

Now you can start a project::

  (aqt-portal-v2)$ pcreate --scaffold starter myProject

Then use normal Python development to setup the project for development::

  (aqt-portal-v2)$ cd myProject
  (aqt-portal-v2)$ setup.py develop

You can start the application using ``pserve`` (similar to django's development
web server)::
  (aqt-portal-v2)$ pserver development.ini --reload
  Starting subprocess with file monitor
  Starting server in PID 72213.
  Starting HTTP server on http://0.0.0.0:6543

Note that the ``development.ini`` file should have been auto-generated by the
previous ``setup.py develop`` command.

After ``pserve`` you should be able to open http://localhost:6543/ in your
browser.


Install cornice
---------------

``cornice`` is a REST framework for ``pyramid`` by *Mozilla Labs*.  Installation
of ``cornice`` is simple::

  (aqt-portal-v2)$ pip install cornice

``cornice`` is packaged as a ``pyramid`` *extension*.  This means that a new
project scaffold should be available::

  (aqt-portal-v2)$ pcreate --list
  Available scaffolds:
    ..
    cornice:                A Cornice application
    ..

See `How-To Cornice`_ for a deeper instruction on how to use ``cornice``.


Install jinja2
--------------

``jinja2`` is a populer python templating engine that was inspired by ``django``
templates.  ``pyramid`` abstracts templating so you can `install`_ ``jinja2``
templates::

  (aqt-portal-v2)$ easy_install pyramid_jinja2

  # You may also use pip...
  (aqt-portal-v2)$ pip install pyramid_jinja2

You will then have to include ``pyramid_jinja2`` in your project's
``__init__.py`` (``myProject/__init__.py)::

  from pyramid.config import Configurator

  def main(global_config, **settings):
    ...
    config.include('pyramid_jinja2')
    ...

.. _`install`: http://docs.pylonsproject.org/projects/pyramid/en/latest/quick_tutorial/jinja2.html

``pyramid_jinja2`` `provides some built-in filters`_ that wrap around ``pyramid``
calls for models, routes, and static files.  If you are using ``jinja2``
templates, you will want to read the linked documentation to learn how to use
and include them.

.. _`provides some built-in filters`: http://docs.pylonsproject.org/projects/pyramid-jinja2/en/latest/#id4


----


.. [#] Why ``easy_install`` and not ``pip``? Pyramid encourages use of namespace
       packages, for which ``pip``'s support is less-than-optimal. Also,
       Pyramid's dependencies use some optional ``C`` extensions for
       performance: with ``easy_install``, Windows users can get these
       extensions without needing a ``C`` compiler (``pip`` does not support
       installing binary Windows distributions, except for ``wheels``, which are
       not yet available for all dependencies).


----


Back to `How-To Pyramid`_.

Back to `Table of Contents`_.



==============
How-To Cornice
==============

``cornice`` has some good documentation `here`_.

.. _`here`: https://cornice.readthedocs.org/en/latest/


#. `Declaring services`_
#. `Validators`_
#. `Services`_
#. `Helpers`_
#. `Testing (with cURL)`_


Testing (with cURL)
-------------------

``cURL`` stands for "Command-line URL" and is a command line application for
calling URLs with specifically formatted HTTP requests and headers.  When
building ``cornice`` RESTful APIs, it comes in handy for testing.

Here is the `documentation`_.

.. _`documentation`: http://curl.haxx.se/docs/manpage.html

Below is a series of cURL commands used for testing ``api_core``::

  # Test if token authorization is working.
  $ curl http://localhost:8000/login
  {"status": 401, "message": "Unauthorized"}

  $ curl -X POST http://localhost:8000/login -H "Content-Type: \
  application/json" -d '{"username":"admin","password":"admin"}'

  {"token": "admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17"}

  $ curl -X GET http://localhost:8000/login -H "Content-Type: \
  application/json" -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17" -d \
  '{"username":"admin","password":"admin"}'

  {"ATMS Web": "atms_web", "ATMS Mobile": "atms_mobile", "ATMS Connect": \
  "atms_connect", "ATMS": "atms"}

  $ curl -X POST http://localhost:8000/webrdp -H "Content-Type: \
  application/json" -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17" -d \
  '{"password":"admin","app_name":"atms","connection_tag":"adminATMS"}'

  {"connection_id": 63}

  $ curl -X DELETE http://localhost:8000/webrdp -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17"

  $ curl -X DELETE http://localhost:8000/login -H "X-Core-Token: \
  admin-23d2e895490cc0d2c5cbf7963f96a6d517067c17"

  {"Goodbye": "admin"}


----


Back to `How-To Cornice`_.

Back to `Table of Contents`_.



==========
Deprecated
==========

#. `Troubleshooting pyodbc`_
#. `Django deployment`_


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


Back to `Troubleshooting pyodbc`_.

Back to `Deprecated`_.

Back to `Table of Contents`_.


Django deployment
-----------------

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


Back to `Django deployment`_.

Back to `Deprecated`_.

Back to `Table of Contents`_.

What is kal-shlib-pretty ?
--------------------------

This is part of ``kal-shlib-*`` package, you should see `documentation`_ of
``kal-shlib-core`` for more general information.

.. _documentation: https://github.com/vaab/kal-shlib-core/blob/master/README.rst


How can install it ?
--------------------

From source
'''''''''''

Consider this release as Very Alpha. Use at your own risk. It may or may not
upgrade to a more user friendly version in future, depending on my spare time.

Nevertheless, this package supports GNU install quite well so a simple::

  # autogen.sh && ./configure && make && make install

Should work (and has been tested and is currently used).

.. note:: you can specify a prefix thanks to ``--prefix=/your/location`` as
  ``configure`` argument.

From debian package
'''''''''''''''''''

A debian package repository is available at::

  deb http://deb.kalysto.org no-dist kal-alpha

you should include this repository to your apt system and then::

  apt-get update && apt-get install kal-shlib-pretty


What are dependencies for this package ?
----------------------------------------

You will need to install::

  kal-shlib-core

before using this package. Note that if you choose the debian package
installation, dependencies will be installed automatically.


What do this package contains ?
-------------------------------

Libraries which are files called ``lib*.sh`` installed in
``$prefix/lib/shlib/``

The debian package version will install directly to this location (knowing that
prefix is ``/usr``)


What these libraries provide ?
------------------------------

Hands on
''''''''

It provides a quick way to get pretty and consistent outputs in ASCII::

      My Title

  My Section
  - My first Elt                   [  OK  ] W
  - My sec Elt            status   [FAILED]
  - My big lengthy desc.. foo      [  OFF ]
  - Just info.

This output is in fancy color by default, and was obtained thanks to these
shell lines::

  Title "My Title"
  Section "My Section"
  Elt "Launching My first Elt"

  ##
  ##  First element
  ##

  print_info_char W   ## prints the "W" at the end of line

  Elt "My first Elt"  ## rewrite the label of the first element

  ## ... launch a script that returns errlvl 0

  Feedback  ## prints the "OK" depending on errlvl, and issue a linefeed.

  ##
  ## Second element
  ##

  Elt "My sec Elt"
  print_info "status"
  print_status "failure"
  Feed

  ##
  ## Third element
  ##

  Elt "My big lengthy description"

  ## ... launch a script that returns errlvl != 0

  Feedback OFF ON foo bar  ## changes defaults OK/FAILED status message
                           ## or even the ``info`` part.

  ##
  ## Final element
  ##

  Elt "Just info."
  Feed                     ## simply issue a line feed.

There's also a all-in-one wrapper of a task I do very often::

  Wrap my-shell-command arg1 arg2 arg3

Will output::

  - my-shell-command ar..          [  OK  ] W

Of course, if you have larger term, the whole command line is diplayed.

And if command fails::

  - my-shell-command ar..          [FAILED] W
  ***** ERROR in wrapped command:
  ***** code:
  my-shell-command arg1 arg2 arg3
  >>>>> Log info follows:
  bash: line 1: my-shell-command: command not found
  <<<<< End Log.
  ***** errorlevel was : 127

All this is in bright yellow and red color, it makes it much more readable.

You can also provide a better description quite easily::

  Wrap -d "My description" my-shell-command arg1 arg2 arg3

Which would naturally display::

  - My description           [  OK  ] W

And last of all, if no command is given on the command line, it'll get your
standard input, which is easier to use ``&&`` or piping or other shell-fu
techniques::

  Wrap -d "Do a lot of things" <<EOF
    my-first-command arg1 arg2 | grep something &&
    my-first-command arg1 arg2
  EOF

Don't forget that Wrap will output the exact same errorlevel so you can
safely::

  Wrap -d "Do a lot of things" <<EOF || exit 1
    my-first-command arg1 arg2 | grep something &&
    my-first-command arg1 arg2
  EOF

to quit your program, or with kal-shlib-common in mind::

  Wrap -d "Do a lot of things" <<EOF || print_error "Argl, I can't continue safely."
    my-first-command arg1 arg2 | grep something &&
    my-first-command arg1 arg2
  EOF

Often, we just want to the command to run quietly, but have the lengthy report
of failure if it fails::

  Wrap -q my-command

Will do the trick.

features
''''''''

These commands ensure that:

  - you can change Title, Section, Elt and subpart of Elt if you haven't issued
    a Feed.

  - the final output can be seen correctly without colors thanks to ansi_color
    environment variable set to "no"

  - color used work well with white or black backgrounds

  - ``Feedback`` and ``Wrap`` commands that change depending on the last
    errorlevel will re-cast the same errorlevel.

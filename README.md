# __estwrapper__

This README is still under construction, sorry...

## What is it?

search database, system, search engine,

**estwrapper** is a set of tools for creating document search database
with [Hyper Estraier](http://fallabs.com/hyperestraier/index.html).

Using estwrapper one can:

* Define which directories to scan and what files to include in the
  index;
* Scan files and index them, thus creating a search database;
* Scan Maildir mail repositories and index them;
* Search the database;
* Obtain information about the search database (files indexed,
  keywords etc.)

## Motivation

[Hyper Estraier](http://fallabs.com/hyperestraier/index.html) is a
great tool -- however, using its command line main interface,
`estcmd`, directly, can be tedious. Additionally, Hyper Estraier
itself does not provide means for defining the directories and files
to index - this is the sole responsibility of its user.

**estwrapper** aims at solving this very problem. Using its
configuration file one can define all the aspects of generation of a
document search database - what directories to scan, what files to
index, what files and file types should be ignored, etc.

Using either `straydoc` (for documents) or `straymail` (for Maildir
format mail) one can create a search database, update it, obtain meta
information about the database, and, of course, search the database.


## Installation

Make sure


### Configuration




## Usage

**Note**: everything said here about `straydoc` holds for
`straymail` - they are used in exactly the same way. They only
slightly differ in their internal implementation.

### Creating a database

Running `straydoc` with no arguments except for those described below
will create (or update) a search database based on the definitions in
the configuration file.

Options:

* `-f <file>` : select a non-default configuration file.
* `-s` : log messages to syslog, instead of printing to stderr.
* `-t` <name> : use `name` to tag log messages, instead of the script
  name.

### Obtaining information

Running `straydoc` with any combination of the switches below will
retrieve different types of information, but will not create an index.

Options:

* `-B` : view the log of the last database build.
* `-H` : search phrase; print results in human-readable format.
* `-I` : print brief database information.
* `-l` : list all the files that would be scanned and indexed. Useful
  for tuning the configuration filters.
* `-L` : list all files registered with the database.
* `-S` : search phrase; symlink found documents in the
  <search-results> directory.
* `-h` : print usage information.

**Note**: `-f` can be used with all of the above options.

Note: see also next section, **Searching**.


## Searching


### Using estseek.cgi


### Using with Mutt



## Contributors


## License





Wrapper around Hyper Estraier search engine for easy creation and
management of document and mail search indexes.


Some ideas from Karl Vogel's and Ben Okopnik's Hyperestraier articles.

(http://linuxgazette.net/158/vogel.html)

(http://linuxgazette.net/159/okopnik.html)

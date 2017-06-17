# __estwrapper__

**estwrapper** is a friendly front-end to
[Hyper Estraier](http://fallabs.com/hyperestraier/), a 
full-text search system.

**estwrapper** allows one to easily scan and index her documents, thus
creating a search-able database. This database can then be searched
either using a web interface powered by a CGI script provided by Hyper
Estraier, or from the command line with **estwrapper** itself.

## What is estwrapper?

Using estwrapper one can:

* Define which directories to scan and what files to include in the
  index;
* Scan files and index them, thus creating a search database;
* Scan Maildir mail repositories and index them;
* Search the database;
* Obtain information about the search database (files indexed,
  keywords etc.)

## Motivation

[Hyper Estraier](http://fallabs.com/hyperestraier/) is a
great tool -- however, using its command line main interface,
`estcmd`, directly, can be tedious. Additionally, Hyper Estraier
itself does not provide means for defining the directories and files
to index - this is the sole responsibility of its user.

**estwrapper** aims at solving this very problem. Using its
configuration file one can define all the aspects of generation of a
document search database - what directories to scan, what files to
index, what files and file types should be ignored, etc.

Using either `straydoc` (for documents) or `straymail` (for Maildir
mail storage format) one can create a search database, update it, obtain meta
information about the database, and, of course, search the database.

* * *

## Table of content

* [Installation](#installation)
  * [Configuration](#configuration)
  * [Filters](#filters)
* [Usage](#usage)

## Installation <a name="installation"></a>

You may install **estwrapper** using the following simple steps:

1. Place the estwrapper scripts `stray_common.sh`, `straydoc`,
   and `straymail` in a directory which is in your PATH.

2. Create directories for the databases you wish to
   create. Recommended structure is to create a main `~/.estwrapper.d`
   directory which contains a separate sub-directory for each
   database, as well as the configuration file (see below).
   
   For example, to create one database for your documents and one for
   your email messages you could use the following single Bash
   command:
   
       mkdir -p ~/.estwrapper.d/{doc,mail}_db
	  
3. Copy the configuration file `estwrapper.conf` to the main
   `~/.estwrapper.d` directory and edit it for your needs.
   
   The most important settings are the directories you wish to index
   and the filters settings. Note that if you choose to have the
   database in a location different than what is described in the
   previous section you should also modify the corresponding settings
   in the configuration file.

By this the major part of the installation is complete. Assuming you
have already installed Hyper Estraier and possibly the utilities
required for the [filters](#filters) you configured, you can now run
either `straydoc` for indexing your documents or `straymail` for
indexing your email messages.

### Configuration <a name="configuration"></a>

System's configuration is read from configuration file that is
searched for in the following locations, in that order:

1. ~/.estwrapper.d/estwrapper.conf
2. ~/.estwrapper.conf
3. /etc/estwrapper.conf

It is also possible to specify a different file using the `-f` command
line switch.

The configuration settings include:

* The directory in which the database is stored;
* List of file types to ignore (e.g., image files);
* List of file types to index;
* [Filter](#filters) definitions.

The configuration file is documented, look at it for additional
information regarding configuration options.

### Filters <a name="filters"></a>

Hyper Estraier can process directly only text and HTML files. In order
to process files of different types they need to be first converted to
either of these types. Hyper Estraier can convert files on the fly and
process them, provided you supply it with an appropriate 'filter' for
the file type you want it to process and instruct it to use it using
command line options.

**estwrapper** comes with filter script for LibreOffice Writer files
and Microsoft Office doc and docx files, that can be enabled or
disabled using configuration settings. Additionally you can use the
configuration option `USER_FILTERS` in order to set additional filters
(In also worth looking at the filters that come with Hyper Estraier),

Note that the filter script in this package require the following
utilities to be available:

* `pdftotext` for PDF files;
* `odt2txt` for ODT files;
* `catdoc` for DOC files;
* `docx2txt` for  DOCX files;

These tools should be available on most Linux distributions.

## Usage <a name="usage"></a>

**Note**: **estwrapper** includes two utilities—`straydoc` for
indexing documents and `straymail` for indexing email messages. Aside
for some differences in the [configuration](#configuration) settings
the usage of these two tools is the same. Hence, in the following
sections, I'll use the token `straydoc` to refer to either of these
tools.

### Creating a database

To create (or update) a search database run `straydoc` with no
option switches or only with any of those described below:

* `-f <file>` : select a non-default configuration file. This switch
  can be used in combination of any other switches.
* `-s` : log messages to syslog, instead of printing to stderr.
* `-t` <name> : use `name` to tag log messages, instead of the script
  name.

The list of directories to search, types of files to index, the
location of the database and additional setting will be taken from the
configuration file.

### Search the database or view database information

To view different types of information about an existing database run
`straydoc` with any combination of the switches below:

* `-h` : print usage information.
* `-B` : view the log of the last database build.
* `-I` : print brief database information.
* `-l` : list all the files that would be scanned and indexed. Useful
  for tuning the configuration filters.
* `-L` : list all files registered with the database.
* `-H <phrase>` : search for phrase; print results to stdout in human-readable format.
* `-S <phrase>` : search for phrase; create symbolic links files that
  are found in a directory specified in the configuration file.

## Searching

### Search from the command line

You can search your documents from the command line with the following
command:

    straydoc -H some-search-pharse
	
the results will be printed in the terminal.

You can also use the command slightly differently:

    straydoc -S some-search-pharse

in which case a symbolic link for each file found will be created in
the directory defined by the `DOC_RESULTS` configuration variable. (if
you would use `straymail`. the links will be created in
`MAIL_RESULTS`.)

Note:
See [Hyper Estraier User's Guide](http://fallabs.com/hyperestraier/uguide-en.html)
for more information about the syntax of search phrases.

### Using a Web Interface

Hyper Estraier provides a CGI script that you can use to search the
index using a web interface, that you can run using a local web
server. This interface is documented in the
[Hyper Estraier User's Guide](http://fallabs.com/hyperestraier/uguide-en.html).

However, in short, this is what one needs to do:

1. Locate the files `estseek.cgi`, `estseek.conf`, `estseek.help`, `estseek.tmpl`,
   and `estseek.top`, and copy them to your CGI director;
2. Edit `estseek.conf`, and modify the `indexname` variable to point
   to your index database directory. This should be a directory named
   `est_db`, located under the directory specified by the
   `DOC_SEARCH_DB` configuration variable (for searching your email
   index this would be `MAIL_SEARCH_DB`);
3. Point your browser to this script.

#### Open Files by local URLs

As a side note, some browsers won't open, by default, local files
pointed to by URLs found on web pages for security reasons. This
behavior won't let you open the files found by the search directly
from the browser.

In Firefox you can workaround this by modifying the browser's
configuration, using the following instructions:

Close all instances of Firefox, then open
~/.mozilla/firefox/<profile_name>/prefs.js in your favorite editor,
and add the following lines:

	user_pref("capability.policy.localfilelinks.checkloaduri.enabled", "allAccess");
	user_pref("capability.policy.localfilelinks.sites", "http://localhost http://127.0.0.1");
	user_pref("capability.policy.policynames", "localfilelinks");

Another option is to use an add-on such as
[LocalLink](http://locallink.mozdev.org/) or similar.

### Search email messages from within Mutt

You can use `straymail` to search email messages from within Mutt
assuming your emails are stored locally in Maildir format.

The idea is as follows:

A Mutt's macro calls `straymail -M`. The user is then prompted for a
search pharse, and after providing it and pressing `Enter`,
`straymail` searches the index and creates symbolic links for the files
found in a special directory. The user can use Mutt to browse this
directory and read the email messages it contains.

Here is an example for such a macro:

    macro generic,index,pager <f6> "<shell-escape>straymail -M<enter>\
    <change-folder><kill-line>=search-results<enter>" \
    "search with Hyper Estraier"

Note that this macro, after invoking `straymail`, changes the mail
folder to `=search-results`, which is a directory named
`search-results` relative to Mutt's `folder`, the default location of
mailboxes.

Also note that the only detail which is dependent on Mail User
Agent's specifics is the ability to run macros, so in principle it should be
possible to apply this technique to other MUAs as well.

## Credits

This whole projects is dependent, of course, on
[Hyper Estraier](http://fallabs.com/hyperestraier/), and many thanks
go to it's author, Mikio Hirabayashi.

Writing this project was inspired by two posts published in the
[Linux Gazette](http://linuxgazette.net/), one by
[Karl Vogel](http://linuxgazette.net/158/vogel.html) and the other by
[Ben Okopnik](http://linuxgazette.net/159/okopnik.html). I borrowed
some of their ideas and tried to improve them. Thanks to both of them.

## License

This project is released under GNU General Public License v3.0.




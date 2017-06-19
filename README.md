# __estwrapper__

**estwrapper** is a friendly front-end to
[Hyper Estraier](http://fallabs.com/hyperestraier/), a full-text
search system. It allows one to easily scan and index her documents,
thus creating a searchable database. This database can then be
searched using either a web interface powered by a CGI script provided
by Hyper Estraier, or from the command line using **estwrapper**
commands.

There are several advantages of using **estwrapper** in regard to
dealing directly with `estcmd`, the low-level Hyper Estraier's main
tool:

* **Configuration File**: Your configuration is persisted in a
  configuration file, so you don't have to provide the details on the
  command line.
* **Intelligent and Flexible File Selection**: You define the
  directories to index, file types to exclude from indexing (thus
  improving performance), specific file types to index, and you can
  also exclude files on a per-directory basis.
* **Various Search Methods**: You can use the tool to search from the
  command line, and it provides a convenient interface for integrating
  it with other tools, for example with the Mutt email client.
* **Database Statistics**: You can retrieve various statistics about
  the search database, such as which files are indexed, information of
  the last database update and so on.

**estwrapper** provides two main tools, similar to each other but
slightly different in operation: `straydoc`  which is used for
indexing and searching documents, and `straymail` which is specific
for indexing and searching email messages (stored in Maildir format).

## Table of content

* [Installation](#installation)
  * [Configuration](#configuration)
  * [Filters](#filters)
* [Usage](#usage)
  * [Creating or Updating a database](#creating-or-updating-a-database)
  * [Viewing database information](#viewing-database-information)
  * [Searching the database](#searching-the-database)
* [Searching Methods in detail](#searching-methods-in-detail)
  * [Searching from the command line](#searching-from-the-command-line)
  * [Searching using a Web Interface](#searching-using-a-web-interface)
  * [Searching email messages from within Mutt](#searching-email-messages-from-within-mutt)
* [Requirements](#requirements)
* [Credits](#credits)
* [License](#license)

## Installation

You can install **estwrapper** using the following steps:

1. Place the estwrapper scripts `stray_common.sh`, `straydoc`, and
   `straymail` in the same directory, and make sure it is included in
   your PATH environment variable.

2. If you want to use the `estfx_office2txt` filter script provided by
   **estwrapper**, place it together with the other scripts above, or
   add its directory to the filters' path using the configuration
   variable FILTER_PATH.

3. Create directories for the databases you wish to create. My
   recommended structure is to create a main `~/.estwrapper.d`
   directory that will contain a separate sub-directory for each
   database, as well as the configuration file (see below).
   
   For example, to create one database for your documents and one for
   your email messages you might want to create the following
   directories: the main directory `$HOME/.estwrapper.d`, a directory
   for your documents' index `$HOME/.estwrapper.d/doc_db` and a
   directory for your email messages' index
   `$HOME/.estwrapper.d/mail_db`.
   
   You can create all the three of them with the following single Bash
   command:
   
       mkdir -p ~/.estwrapper.d/{doc,mail}_db
	  
4. Copy the configuration file `estwrapper.conf` to the main
   `~/.estwrapper.d` directory and edit it to fit your needs.
   
   The most important settings are the directories you wish to index
   and the filters settings. Note that if you choose to have the
   database in a location different than what is described in the
   previous section you should also modify the corresponding settings
   in the configuration file.
   
   Here is an example of the settings that you should inspect and
   possibly modify:
	   
	   # databases location
       DOC_SEARCH_DB="$HOME/.estwrapper.d/doc_db"
       MAIL_SEARCH_DB="$HOME/.estwrapper.d/mail_db"
	   # directories to index
       DOC_DIRS=("$HOME/Documents" "$HOME/Dropbox")
       MAIL_DIRS=("$HOME/Mail/main/INBOX" "$HOME/Mail/main/Sent")

   Another variable that you may want to define is FILTER_PATH which
   defines the search path for filters. It has the same syntax as the
   system's PATH shell variable. For example:

       FILTER_PATH=$HOME/bin/filters:$HOME/bin

This should complete the installation, except for some possible fine
tuning. Assuming you have already installed Hyper Estraier and
possibly the utilities required for the [filters](#filters) you
configured, you can now run either `straydoc` for indexing your
documents or `straymail` for indexing your email messages.

### Configuration

System's configuration is read from configuration file that is
searched for in the following locations, in that order:

1. `~/.estwrapper.d/estwrapper.conf`
2. `~/.estwrapper.conf`
3. `/etc/estwrapper.conf`

It is also possible to specify a different file using the `-f` command
line option.

The configuration settings include:

* The directory in which the database is stored;
* List of file types to ignore (e.g., image files);
* List of file types to index;
* [Filter](#filters) definitions.

The configuration file is documented, look at it for additional
information regarding available configuration options.

### Filters

Hyper Estraier can process directly only text, HTML and email RFC 822
files. In order to process files of other types they need to be
converted to either text or HTML. Hyper Estraier can convert files on
the fly and then process them, provided you supply it with an
appropriate 'filter' for the file type you want it to process and
instruct it to use (which you can do using settings in
**estwrapper**'s configuration file).

**estwrapper** comes with filter script for LibreOffice Writer files
and Microsoft Office doc and docx files, that can be enabled or
disabled using configuration settings. Additionally you can use the
configuration option `USER_FILTERS` in order to set additional filters
(It's also worth looking at the filters that come with Hyper Estraier),

See the [Requirements](#requirements) section for information
regarding the tools that are required for **estwrapper**'s filter script.

## Usage

**Note**: **estwrapper** includes two utilities—`straydoc` for
indexing documents and `straymail` for indexing email messages. Aside
for some differences in the [configuration](#configuration) settings
the usage of these two tools is the same. Hence, in the following
sections, I'll use the token `straydoc` for referring to either of
these tools.

### Creating or Updating a database

To create (or update) a search database run `straydoc` with no
option switches or with a combination of only the following options:

* `-f <file>` : select a non-default configuration file. This switch
  can be used in combination with any other switches.
* `-s` : log messages to syslog, instead of printing to stderr.
* `-t` <name> : use `name` to tag log messages, instead of the script
  name.

The list of directories to search, types of files to index, the
location of the database and additional setting will be taken from the
configuration file.

### Viewing database information

To view different types of information about an existing database run
`straydoc` with any combination of the switches below:

* `-h` : print usage information.
* `-B` : view the log of the last database build.
* `-I` : print brief database information.
* `-l` : list all the files that would be scanned and indexed. Useful
  for tuning the configuration filters.
* `-L` : list all files registered with the database.

### Searching the database

* `-H <phrase>` : search for phrase; print results to stdout in human-readable format.
* `-S <phrase>` : search for phrase; create symbolic links files that
  are found in a directory specified in the configuration file.
* `-P` : similar to `-S`, but the user is prompted for the search phrase.

See the following section for more details.

## Searching Methods in detail

The following sections describe different ways for searching the
document or email databases.

### Searching from the command line

You can search your documents from the command line with the following
command:

    straydoc -H some-search-pharse
	
the results will be printed to the standard output in a human readable
format.

If you use the following command:

    straydoc -S some-search-pharse

instead of printing the results a symbolic link for each file found
will be created in the directory defined by the `DOC_RESULTS`
configuration variable. (if you would use `straymail`, the links will
be created in `MAIL_RESULTS`.)

You could also use:

	straydoc -P
	
which works similarly to the `-S` option, except that, instead of
supplying the search phrase as an argument, you'll be interactively
prompted to supply it. This option might be useful when `straymail`
(or `straydoc`) is called by another tool and needs to be interactive.

Note:
See [Hyper Estraier User's Guide](http://fallabs.com/hyperestraier/uguide-en.html)
for detailed information on the syntax of search phrases.

### Searching using a Web Interface

Hyper Estraier provides a CGI script that you can use to search the
index using a web interface, that you can run using a local web
server. This interface is documented in the
[Hyper Estraier User's Guide](http://fallabs.com/hyperestraier/uguide-en.html).

However, in short, this is what one needs to do:

1. Locate the files `estseek.cgi`, `estseek.conf`, `estseek.help`, `estseek.tmpl`
   and `estseek.top`, and copy them to your CGI directory;
2. Edit `estseek.conf`, and modify the `indexname` variable to point
   to your index database directory. This should be a directory named
   `est_db`, located under the directory specified by the
   `DOC_SEARCH_DB` configuration variable (for searching your email
   index this would be `MAIL_SEARCH_DB`);
3. Point your browser to the CGI script and start searching.

#### Open Files by local URLs

As a side note, some browsers won't, by default, open local files
pointed to by URLs found on web pages for security reasons. When this
is the case the browser won't let you open the files found by the
search directly when you click on them.

In Firefox you can workaround this by modifying its configuration,
using the following instructions:

Close all instances of Firefox, then open
~/.mozilla/firefox/<profile_name>/prefs.js in your favorite editor,
and add the following lines:

	user_pref("capability.policy.localfilelinks.checkloaduri.enabled", "allAccess");
	user_pref("capability.policy.localfilelinks.sites", "http://localhost http://127.0.0.1");
	user_pref("capability.policy.policynames", "localfilelinks");

Another option, not requiring fiddling with Firefox's configuration,
is to use an add-on such as [LocalLink](http://locallink.mozdev.org/)
or similar.

### Searching email messages from within Mutt

If you store your emails locally in Maildir format, you can easily
search them with `straymail` from within Mutt.

One simple way to do that is using a Mutt macro that calls `straymail
-P`, which will prompts the user for a search phrase, search for it
and symbolicly link the messages found in the directory defined by
**estwrapper**'s MAIL_RESULTS configuration variable.

You can then point Mutt to this directory and browse the email
messages it contains.

Here is one possible example for such a macro:

    macro generic,index,pager <f6> "<shell-escape>straymail -P<enter>\
    <change-folder><kill-line>=search-results<enter>" \
    "search with estwrapper"

Note that after this specific macro runs `straymail` it changes the
current mail folder to `=search-results`, which is a directory named
`search-results` relative to Mutt's `folder`, the default location of
Mutt's mailboxes. The `search-results` directory should be a standard
Maildir folder created beforehand.

To be complete, this is how the search results directory is defined in
**estwrapper**'s configuration file:

    MAIL_RESULTS=$HOME/Mail/search-results/cur

and these are the corresponding settings it Mutt's configuration file:

    set folder = ~/Mail
    mailboxes +search-results

You can create the `search-results` directory with a command such as
`maildirmake`, thus making sure it is in the correct format.

Also note that the only detail which is dependent on an Email client's
specifics is the ability to run macros, so in principle it should be
possible to apply this technique to other Email clients as well.

## Requirements

Obviously, the Hyper Estraier system must be installed. You can
install it from your Linux distribution package manager, or obtain it
from the main
[Hyper Estraier web site](http://fallabs.com/hyperestraier/). On
Debian the package is, surprise, `hyperestraier`.

**estwrapper**'s filter script, that can be used to convert
LibreOffice Writer and Microsoft Office doc and docx files to text to
enable indexing them, needs the following utilities:

* `odt2txt` for ODT files;
* `catdoc` for DOC files;
* `docx2txt` for  DOCX files;

On Debian they are provided by packages with similar names.

Hyper Estraier provide some filters for processing several types of
files, including man files and PDF files. For PDF files you'll need to
have `pdftotext`, which on Debian comes with the `poppler-utils` package.

## Credits

This whole projects is dependent, of course, on
[Hyper Estraier](http://fallabs.com/hyperestraier/), and many thanks
go to it's author, Mikio Hirabayashi.

Writing this project was inspired by two articles published in the
[Linux Gazette](http://linuxgazette.net/), one by
[Karl Vogel](http://linuxgazette.net/158/vogel.html) and the other by
[Ben Okopnik](http://linuxgazette.net/159/okopnik.html). I borrowed
some of their ideas and tried to improve them. Thanks to both of them.

## License

This project is released under GNU General Public License v3.0.




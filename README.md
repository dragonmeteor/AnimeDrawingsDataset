Anime Drawings Dataset
======================

A dataset for 2D pose estimation of anime/manga images.  This repository contains code to:

  * Download images from the Internet and process them.
  * Generate HTML files that allow the user to view the dataset.

Dependencies
------------

  * The Ruby programming language.
  * The following Ruby packages. (You only need to have the first one installed.)
    * `bundler` (for installing the following two packages)
    * `rake` (for automation)    
    * `nokogiri` (for HTML processing)
    * `mechanize` (for interaction with web pages)
  * ImageMagick
    * You should be able to run the `convert` command from the shell.

Preparing the Dataset
---------------------

First, please clone the dataset into a directory of your choice.  Then, change into the directory of the repository.  At this point, you should have (1) the Ruby language, (2) the `bundler` package, and (3) ImageMagick installed in your system.

The next step is to install other Ruby packages.  Run:

> `bundle install`

Then, run:

> `rake build`

The above command will download all the images and process them.  This can take some time, so sit back, relax, and wait.

After the above command finishes, you can browse the dataset by viewing the HTML page `index.html` in the root of the repository.
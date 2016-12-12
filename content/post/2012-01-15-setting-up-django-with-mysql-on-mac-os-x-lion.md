---
title: Setting up Django with MySQL on Mac OS X Lion
author: Ryan
layout: post
date: 2012-01-16T02:59:00+00:00
url: /2012/01/15/setting-up-django-with-mysql-on-mac-os-x-lion/
dsq_thread_id:
  - 540748289
tags:
  - Software

---
Surprisingly, this is a lot more annoying that I thought it would be. Some
notes to the forgetful future me:

1. [Download][1] the MySQL .dmg installer (64-bit). The registration form can
   be skipped.
1. Install MySQL, the MySQLStartupItem, and the MySQL.prefPane in that order
   (See <http://stackoverflow.com/questions/6317614/getting-mysql-work-on-osx-10-7-lion>)
1. Open up the MySQL preference pane and make sure the server is started.
1. Edit `~/.bash_profile` and make sure that the mysql bin directory is in the
   path (`/usr/local/mysql/bin`). (The MySQL-python package needs to call `mysql_config`)
1. Add a libmysqlclient symlink: `sudo ln -s /usr/local/mysql/lib/libmysqlclient.18.dylib /usr/lib/libmysqlclient.18.dylib`
1. `pip install MySQL-python`

Phew. Don't forget to update your django SETTINGS file for running locally:

~~~python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': DATABASE_NAME,
        'USER': USER,
        'PASSWORD': PASSWORD,
        'HOST': 'localhost'
    }
}
~~~

 [1]: http://dev.mysql.com/downloads/mysql/
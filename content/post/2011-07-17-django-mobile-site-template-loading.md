---
title: Django mobile site template loading
author: Ryan
layout: post
date: 2011-07-17T16:12:52+00:00
url: /2011/07/17/django-mobile-site-template-loading/
dsq_thread_id:
  - 360724859
tags:
  - Software

---
Building out a mobile version of a site is increasingly becoming a must-have
feature these days. From a maintainability perspective however, it is important
not to intermingle too much conditional markup within a single template (eg,
"If this is the mobile version, render this, otherwise render that"). A better
approach is to use a separate mobile template and fallback to the regular site
template if the mobile one cannot be found.

<http://sullerton.com/2011/03/django-mobile-browser-detection-middleware/>
outlines a nice, clean way of accomplishing this in Django with middleware and
a custom template loader:


  1. Use middleware to detect whether the user-agent string in the request is
     from a mobile browser. Store a value indicating what version of the
     templates to load in a thread-local.
  2. Create a custom template loader that reads the flag from the thread-local
     and loads the appropriate version of the template or fall back to the
     default version if it doesn't exist.


The thread-local hackery is actually a nice way of getting around the issue of
trying to pass values from the middleware to the template loader. There are a
couple of small tweaks that can be made to the template loader however to
improve things a bit.

The template loader outlined in the post above makes an assumption around where
the mobile templates will be stored on disk. It would be nicer if you could use
the existing template loaders that come with django to load your mobile
template. For example, if you are creating a reusable django app, it would be
nice to bundle your mobile templates in the same directory as your full site
templates. Or, if you are one of the crazy people loading their templates from
a Python egg, it would be nice to be able to stick your mobile templates into
the same egg and use the built-in egg loader to load the appropriate one.

~~~python
from django.template.base import TemplateDoesNotExist
from django.template.loader import BaseLoader
import django.template.loader

class Loader(BaseLoader):
    is_usable = True

    @property
    def other_loaders(self):
        for loader in django.template.loader.template_source_loaders:
            if loader != self:
                yield loader

    def load_template_source(self, template_name, template_dirs=None):
        site_version = get_version()
        if site_version != 'full':
            mobile_template_name = "%s/%s" % (site_version, template_name)

            for loader in self.other_loaders:
                try:
                    return loader.load_template_source(mobile_template_name, template_dirs)
                except TemplateDoesNotExist:
                    pass

        raise TemplateDoesNotExist(template_name)
~~~

First thing to note is that this template loader adheres to the new class-based
API that was introduced in Django 1.2.

`getVersion()` is the method that returns the string that was stored in the
thread-local by the middleware. It returns either 'full' or 'mobile'. Depending
on how many different site variations you wanted to support, you could modify
the middleware to set more granular identifiers like 'ios' or 'android' instead
of just 'mobile'.

Rather than load the contents of a template directly, this loader will delegate
to the 'real' loaders that are defined in the settings file when it looks for
the mobile version of a template. So, suppose your settings file looks like
this:

~~~python
TEMPLATE_LOADERS = (
    'templateloader.Loader',
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
)
~~~

If a request is made for the mobile version of "base.html", the loader will see
if it can find the "mobile/base.html" with the filesystem Loader, then it will
try the app\_directory Loader. If it still doesn't find it, the loader will
then fallback to the initially requested "base.html". Of course, in order for
this to work, it is critical that the custom template loader class appear first
in the TEMPLATE\_LOADERS tuple.

The templates are organized into parallel directories that are structured as
follows:

<pre>
/templates/base.html
/templates/home.html
/templates/mobile/base.html
/templates/mobile/home.html
</pre>

The `django.template.loader.template_source_loaders` used in the
`other_loaders` property is a global array that gets initialized in the
`django.template.loader.find_template` method and contains instances of the
template loaders that are defined in the settings file. I'm assuming that
`find_template` will always be called before control passes to the
`load_template_source` method in this custom template loader.

Would love to hear any feedback on this approach.
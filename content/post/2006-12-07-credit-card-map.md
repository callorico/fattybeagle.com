---
title: Credit Card Map
author: Ryan
layout: post
date: 2006-12-07T09:55:23+00:00
url: /2006/12/07/credit-card-map/
dsq_thread_id:
  - 524691696
tags:
  - Google Maps
  - Road Trip
  - Software

---
As I was looking through my credit card statements the other day and wincing
over the cost of the road trip, I realized that you could sort of recreate my
path across the country by stitching together the cities listed for the various
charges. And so, I present to you the official Road Trip Credit Card Map:

<iframe src="/map/map.html" style="width:100%; height: 410px" frameborder=0 scrolling=no></iframe>

I whipped up a few Ruby scripts (source [here][1]) to scrape the transactions
from the HTML (oddly, the more easily parseable export formats offered by Citi
and Chase such as CSV don't provide the city and state information), looked up
with lat, lng coordinates with the Google Maps geocoder, and then dumped the
whole mess to an XML file that is then read in by the Google Maps javascript
API.

One problem with this is that sometimes the charge date doesn't match the
actual date of purchase so it looks like there is some backtracking that didn't
occur. Also, the city and state listed for the transaction doesn't always match
the place where I made the charge. And finally, some of the city names are
mangled and unrecognized by the geocoder. These need to be corrected by hand.
Still, I think it is a fairly accurate representation.

I've only tested it on IE7 and Firefox2 so your mileage may vary depending on
your browser of choice. Lemme know if it doesn't work. And yes, I did eat at an
Applebee's once. /me hangs head in shame.

 [1]: /map/source.zip

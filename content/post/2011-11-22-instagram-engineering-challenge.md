---
title: Instagram Engineering Challenge
author: Ryan
layout: post
date: 2011-11-23T04:14:41+00:00
url: /2011/11/22/instagram-engineering-challenge/
dsq_thread_id:
  - 480982747
tags:
  - Software

---
Darn, I'm pretty late to the [Instagram Engineering Challenge][1] party but it
was still a fun little puzzle to solve even if there is no free schwag left.

Some of the [Hacker News][2] crowd felt it was too easy but I thought it struck
the right balance between too easy and too much work for a take-home recruiting
problem. Besides, as others pointed out, you can always remove some of the
simplifying assumptions (images don't have large blocks of repeating colors,
adjacent shreds will never be in the correct order, etc) and you can make the
problem as difficult as you want it to be.

The general solution sketch is fairly obvious: Compare colors in adjacent
vertical pixel strips and if they are "close" to each other then the two strips
should be adjacent to each other in the unshredded image. As far as distance
metrics go, measuring the euclidean distance between two RGBA pixels and
summing up the values for each pixel in the strip is the first thing that comes
to mind.

The above seemed like a reasonable avenue of attack but, alas, the devil is in
the details as they say.

The first bump in the road that came up was trying to determine what the first
shred in the image is. For this, I ended up measuring the distance between
every pair of shreds. For each shred, you can then determine what its preceding
shred is by picking the one with the smallest distance value. The shred whose
smallest distance value is the greatest amongst all shreds likely doesn't have
a previous shred and is thus the left-most shred in the image.

Next, I noticed that the algorithm was having problems with the tall black and
white building in the photo. The building is unfortunately split right along a
white-black transition. This causes the adjacent pixels to be rather different
from each other:

[<img
src="/images/unshredded.png"
alt="" title="unshredded" width="640" height="359" class="alignnone size-full
wp-image-284"
srcset="/images/unshredded.png
640w,
images/unshredded-300x168.png
300w" sizes="(max-width: 640px) 100vw, 640px" />][3]

To fix this, I needed a way to smooth out the colors used in the strips. So,
rather than consider each pixel in isolation, I calculated the average color of
the pixel and its surrounding neighbors (a 3&#215;3 mask seemed to work ok on
this image).

Finally, for the extra credit problem of automatically determining the shred
width, I measured the distance between adjacent vertical pixel strips. My
thinking was that the distance values should be relatively small until it
reaches another shred at which point the distance value will spike. I then
normalized the distance values by recasting them as the number of standard
deviations away from the mean. Since there is a simplifying assumption that
each shred has a uniform width, the normalized distance can be checked at those
discrete spots and if each value exceeds a threshold, then we'll use that as
the shred width.

Fun way to spend an afternoon :). The python code is below and it is completely
untested on any other image of course.

{{< gist callorico 1387866 >}}

 [1]: http://tumblr.com/ZElL-wBo6VHr
 [2]: http://news.ycombinator.com/item?id=3225911
 [3]: /images/unshredded.png
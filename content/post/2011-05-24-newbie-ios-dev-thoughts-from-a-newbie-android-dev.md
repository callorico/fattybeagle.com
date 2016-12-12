---
title: Newbie iOS dev thoughts from a newbie Android dev
author: Ryan
layout: post
date: 2011-05-25T05:45:35+00:00
url: /2011/05/24/newbie-ios-dev-thoughts-from-a-newbie-android-dev/
dsq_thread_id:
  - 313153073
tags:
  - Android
  - iOS

---
Egads, looks like I slipped my self-imposed release date for the iOS version of
[Recipe Distiller][1] by about a month. Mea culpa! Beyond the obvious issue of
not scrounging together enough free time to work on it, there were several
non-obvious issues that cropped up along the way that took longer to deal with
than I had initially expected:

### Calling a series of web service methods sequentially

Recipe Distiller exposes a RESTful web service that clients can use to extract
recipe ingredients and manage grocery lists. There are several places where a
client needs to call a service method A, read some values from the response
message and then pass values from A's response to another service method B.
Unfortunately, the dependencies between service method calls doesn't jibe well
with the asynchronous connection methods of the NSURLConnection. While it is
possible to initialize and kick off another connection request for service
method B after A completes successfully, this quickly leads to spaghetti code
and it can be difficult to follow the "call method A then method B" logic.
Things can spiral out of control once you have additional dependencies between
service calls. This was easier to manage with the Android version of the app
because it was possible to spawn a worker thread and then make synchronous
calls to the service in the background. While the NSURLConnection does respond
to a message that sends a synchronous request to the service, it supports fewer
options than the asynchronous call.

What I ended up doing was creating separate NSOperation subclasses for each
service method call, creating dependencies between them, and running them on a
shared NSOperationQueue. This actually ended up working out pretty well in
practice as the NSOperation subclasses are nicely encapsulated and can be
assembled together in different combinations if there are different dependency
requirements. The only strange thing about all of this is that it seems like
the asynchronous connection methods on the NSURLConnection do not work if it
they are kicked off on a background thread and by default that is the thread
that the NSOperation start message runs on. You can workaround this issue by
marshalling the start method back to the main UI thread:

~~~objc
-(void)start {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }

	NSURLRequest *request = nil;
	if ([self isCancelled] || !(request = [self createRequest])) {
		// Must move the operation to the finished state if it is canceled.
		[self willChangeValueForKey:@"isFinished"];
		_isFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}

	// If the operation is not canceled, begin executing the task.
	[self willChangeValueForKey:@"isExecuting"];

	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	self.connection = aConnection;
	[aConnection release];

	_isExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
}
~~~

### Keeping strong references to NSManagedObject instances

I thought CoreData was pretty nifty way of managing persistent data. It
definitely beats the homegrown, half-implemented ORM I ended up creating for
the Android version of the app. The general CoreData usage pattern I started
with was basically copied from a couple of sample projects I had seen: A
UITableView populated with a NSFetchedResultsController displaying a list of
recipes or grocery items. Tapping a row initializes a new details controller
that maintains a strong reference to the NSManagedObject.

The Recipe Distiller app supports a background sync operation with the server
that causes havoc with the above approach. It is possible for a NSManagedObject
to be deleted as part of the background sync while a details controller view is
being displayed to the user (note that the actual manipulation of the
NSManagedObject is happening on the UI thread so there is no issue of trying to
use the NSManagedObjectContext from multiple threads going on here). Once the
NSManagedObject is deleted from the context, it is automatically faulted out
but cannot be deleted because the details controller is still hanging onto it.
Now, when the controller attempts to read values from the managed object to
display in the view, a [fault cannot be fulfilled error][2] will occur.

To workaround this, I ended up having the details controller store a reference
to the NSManagedObjectID of the managed object along with any other non-managed
object fields that it needs to display. Then, when the user attempts to save
any changes, the object ID is used to lookup the managed object. If the object
still exists, any changes made on the details view are set into the managed
object and saved, otherwise, the details controller is simply popped off the
navigation stack.

### Programmatically adding Mobile Safari bookmarklets

Can't do it.

Recipe Distiller relies on integrating itself into the browser to allow users
to capture recipes on a web page being viewed. Android makes it easy to do this
by registering an intent filter in your application manifest. Unfortunately, it
is hugely painful to do this on iOS devices and relies on a lot of manual steps
from the user and I'm positive that this is going to be a dealbreaker for a lot
of users. I'm pretty sure there is no better way to do this as of right now
(iOS 4.3). Other apps that behave similarly to Recipe Distiller like
[Instapaper][3] also have this same issue.

In an ideal world, every recipe site owner would add a "Save Recipe" link to
their recipes. This would be very similar to the Reddit, Facebook Like, Digg,
et. al buttons that litter then web. I doubt that the big sites would be
willing to do this as they want to lock users into their own grocery list and
recipe management toolsets but I can see Recipe Distiller being a nice value
add for blog writers that don't have the time or wherewithal to build this
stuff on their own. Getting the long, long tail of bloggers to buy in is for
Part 2 of Recipe Distiller World Domination.

### Inability to reuse app names in itunes Connect

My typical click first and ask questions later approach really screwed me up
here. In my impatience, I entered the incorrect Bundle ID when I created the
application in iTunes Connect so the app validation was failing in XCode. I
figured I'd be able to just delete the app I had created and recreate it. I'm
an idiot for not heeding the warning message which appeared when I selected
Delete App but I incorrectly assumed that I'd be able to reuse an app name if
it had never been given an associated binary or made available in the app
store. Imagine my horror once I stumbled this [Stack Overflow][4] post telling
me I was out of luck. I also learned that iTunes Connect will also consider app
names that differ only by casing or whitespace as being the same. Sad panda.

Anyhow, I have to admit that all in all, it was a semi-enjoyable ride dabbling
with the iOS SDK. The out-of-the-box UI controls and animations are much more
polished-looking than the Android equivalents. I found the syntax rather
inelegant-looking and the old school split of header and implementation files
meant that I found myself constantly copy/pasting between (it is somewhat
frightening how many different things you need to change . Recipe Distiller,
err "Recipe Distiller for iPhone", was submitted for review last night and I'm
hoping to have it available on the App Store soon.

 [1]: http://recipedistiller.com
 [2]: http://developer.apple.com/library/ios/#DOCUMENTATION/Cocoa/Conceptual/CoreData/Articles/cdTroubleshooting.html
 [3]: http://www.instapaper.com/i__?Paste_here_and_replace_this
 [4]: http://stackoverflow.com/questions/3377534/deleting-an-app-in-itunes-connect
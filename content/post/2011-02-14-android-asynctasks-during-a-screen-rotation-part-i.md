---
title: Android AsyncTasks during a screen rotation, Part I
author: Ryan
layout: post
date: 2011-02-14T23:31:47+00:00
url: /2011/02/14/android-asynctasks-during-a-screen-rotation-part-i/
dsq_thread_id:
  - 235480685
tags:
  - Android

---
During development of the Android [Recipe Distiller][1] app, I ran into a
subtle issue around the usage of the AsyncTask class.  It ended up being a
little trickier than I thought it would be to perform the relatively mundane
task of bringing up a progress dialog and making a webservice call in the
background. This first part goes over some of the suggested solutions and the
next post will go over what I ended up implementing.

My initial implementation started with the AsyncTask as an inner class of the
Activity.  A progress dialog was created in onPreExecute, the web service call
made in doInBackground, and then the dialog was dismissed in onPostExecute.
This was all well and good until you tried rotating the screen at which point
the app would crash.

Basically, the issue is that once you call execute() on the AsyncTask, the
thread performing the long running operation will continue doing its thing
regardless of the state of the Activity that spawned it.  When the screen is
rotated, the Activity is destroyed and a new instance is created.  The problem
is that any currently running AsyncTasks will now be operating against the
destroyed Activity instance and Very Bad Things will ensue.

There are a number of threads at StackOverflow going over this issue.  Here is
one of them:

<http://stackoverflow.com/questions/2620917/how-to-handle-an-asynctask-during-screen-rotation>

In the [Shelves][2] application, within the onSaveInstanceState method, there
is a check to see if there are any currently running AsyncTasks.  If so, it is
cancelled and its current state is saved to the bundle.  In
onRestoreInstanceState, if the AsyncTask state exists in the bundle, a new
AsyncTask instance is created for the new Activity and it is immediately
executed.

(Note: This has been edited for brevity)

~~~java
@Override
protected void onSaveInstanceState(Bundle outState) {
    super.onSaveInstanceState(outState);
    final AddTask task = mAddTask;
    if (task != null && task.getStatus() != UserTask.Status.FINISHED) {
        final String bookId = task.getBookId();
        task.cancel(true);

        if (bookId != null) {
            outState.putBoolean(STATE_ADD_IN_PROGRESS, true);
            outState.putString(STATE_ADD_BOOK, bookId);
        }

        mAddTask = null;
    }
}

@Override
protected void onRestoreInstanceState(Bundle savedInstanceState) {
    super.onRestoreInstanceState(savedInstanceState);
    if (savedInstanceState.getBoolean(STATE_ADD_IN_PROGRESS)) {
        final String id = savedInstanceState.getString(STATE_ADD_BOOK);
        if (!BooksManager.bookExists(getContentResolver(), id)) {
            mAddTask = (AddTask) new AddTask().execute(id);
        }
    }
}
~~~

This feels somewhat unsatisfactory since it seems rather inefficient to
potentially repeat the same expensive network call just because the device was
rotated in the middle of the operation.

[This thread][3] outlines another approach that leverages the
onRetainNonConfigurationInstance callback.  In a nutshell:

  * AsyncTasks are made static inner classes so they do not retain the implicit
    reference to the parent Activity.  Instead, an Activity reference is
    explicitly passed to the task.
  * When the Activity is being destroyed as part of a screen orientation
    change, the AsyncTask's Activity reference is nulled out.  The AsyncTask
    callback methods that run in the UI thread perform a null check on the
    Activity before trying to make any UI changes.
  * When the new Activity gets created, the new instance is passed to the
    AsyncTask.

Taking a quick glance at the [code][4] should make this clear.

While this solution seems fine for the screen rotation case, I don't think it
will work correctly in the following situation:

  1. AsyncTask started inside of Activity A
  2. Phone call comes in and a new Activity is brought to the foreground.
  3. Android decides to destroy Activity A

In this situation I don't believe the onRetainNonConfigurationInstance method
will ever be called if I understand the Activity lifecycle correctly. Anytime
another Activity comes to the foreground, it is possible that Android will kill
the previous Activity in certain low-memory situations.

The nice thing about this approach however is that it provides a way to hand
off the AsyncTask instance from the Activity being destroyed to the new one
that gets created after the screen rotation.  This way, the expensive operation
only needs to happen once.  With the above scenario however, there isn't any
way for the newly created Activity to get a reference to the previously spawned
AsyncTask.

[Part II][5] will go over the workaround for this that I cobbled together.

 [1]: http://recipedistiller.com
 [2]: http://code.google.com/p/shelves/
 [3]: http://groups.google.com/group/android-developers/browse_thread/thread/e1d5b8f8a3142892#
 [4]: https://github.com/commonsguy/cw-android/blob/master/Rotation/RotationAsync/src/com/commonsware/android/rotation/async/RotationAsync.java
 [5]: /2011/02/15/android-asynctasks-during-a-screen-rotation-part-ii/
---
title: Android AsyncTasks during a screen rotation, Part II
author: Ryan
layout: post
date: 2011-02-15T20:27:16+00:00
url: /2011/02/15/android-asynctasks-during-a-screen-rotation-part-ii/
dsq_thread_id:
  - 239904143
tags:
  - Android

---
[Part I][1] went over a couple of proposed solutions for dealing with the
problem of the Activity being destroyed during a screen orientation change
while an AsyncTask is running.

The technique of using onRetainNonConfigurationInstance and
getLastNonConfigurationInstance to pass an AsyncTask reference from the
Activity instance being destroyed to the new one being created is a good one
but does not appear to handle the case when an Activity is destroyed and
recreated outside of a configuration change (eg, Android might kill your
non-foreground Activity in low-memory situations).  In that situation, the
reference to the AsyncTask is essentially lost and there isn't any way to tell
it about the new Activity instance.

What I ended up doing to workaround this issue was to store references to the
AsyncTask inside of the _Application_ object instead.  The major assumption
that I am making here is that the lifetime of the Application instance matches
that of the process and will stick around even as Activities are destroyed and
created (crossing fingers).  A custom AsyncTask class automatically saves a
reference to itself with the Application when it is executed and will also
remove itself from the Application when it completes to prevent a memory leak.

The Activity is responsible for notifying the application when it is being
destroyed and restarted in onSaveInstanceState.  The CustomApplication class
will lookup all AsyncTasks that have been started on behalf of the Activity and
null out their Activity reference.  When the new Activity instance is created
and initialized, the onRestoreInstanceState method notifies the
CustomApplication again and it will pass the new Activity reference to all of
the AsyncTasks that are still running.

CustomApplication.java:

~~~java
public class CustomApplication extends Application {
	/**
	 * Maps between an activity class name and the list of currently running
	 * AsyncTasks that were spawned while it was active.
	 */
	private Map<String, List<CustomAsyncTask<?,?,?>>>; mActivityTaskMap;

	public CustomApplication() {
		mActivityTaskMap = new HashMap<String, List<CustomAsyncTask<?,?,?>>>();
	}

	public void removeTask(CustomAsyncTask<?,?,?> task) {
		for (Entry<String, List<CustomAsyncTask<?,?,?>>> entry : mActivityTaskMap.entrySet()) {
			List<CustomAsyncTask<?,?,?>> tasks = entry.getValue();
			for (int i = 0; i < tasks.size(); i++) {
				if (tasks.get(i) == task) {
					tasks.remove(i);
					break;
				}
			}

			if (tasks.size() == 0) {
				mActivityTaskMap.remove(entry.getKey());
				return;
			}
		}
	}

	public void addTask(Activity activity, CustomAsyncTask<?,?,?> task) {
		String key = activity.getClass().getCanonicalName();
		List<CustomAsyncTask<?,?,?>> tasks = mActivityTaskMap.get(key);
		if (tasks == null) {
			tasks = new ArrayList<CustomAsyncTask<?,?,?>>();
			mActivityTaskMap.put(key, tasks);
		}

		tasks.add(task);
	}

	public void detach(Activity activity) {
		List<CustomAsyncTask<?,?,?>> tasks = mActivityTaskMap.get(activity.getClass().getCanonicalName());
		if (tasks != null) {
			for (CustomAsyncTask<?,?,?> task : tasks) {
				task.setActivity(null);
			}
		}
	}

	public void attach(Activity activity) {
		List<CustomAsyncTask<?,?,?>> tasks = mActivityTaskMap.get(activity.getClass().getCanonicalName());
		if (tasks != null) {
			for (CustomAsyncTask<?,?,?> task : tasks) {
				task.setActivity(activity);
			}
		}
	}
}
~~~

CustomAsyncTask.java:

The task registers itself with the CustomApplication in onPreExecute and then
removes itself once it has finished running (onCancelled and onPostExecute).
The setActivity method is used to null out the Activity reference when the
spawning Activity is getting destroyed and also to push in the new Activity
instance.

~~~java
public abstract class CustomAsyncTask<TParams, TProgress, TResult> extends AsyncTask<TParams, TProgress, TResult> {
	protected CustomApplication mApp;
	protected Activity mActivity;

	public CustomAsyncTask(Activity activity) {
		mActivity = activity;
		mApp = (CustomApplication) mActivity.getApplication();
	}

	public void setActivity(Activity activity) {
		mActivity = activity;
		if (mActivity == null) {
			onActivityDetached();
		}
		else {
			onActivityAttached();
		}
	}

	protected void onActivityAttached() {}

	protected void onActivityDetached() {}

	@Override
	protected void onPreExecute() {
		mApp.addTask(mActivity, this);
	}

	@Override
	protected void onPostExecute(TResult result) {
		mApp.removeTask(this);
	}

	@Override
	protected void onCancelled() {
		mApp.removeTask(this);
	}
}
~~~

TestActivity.java:

Note that the DoBackgroundTask inner class is static so as to avoid creating an
implicit reference to the Activity.  Also note that the mActivity reference
needs to be checked for null in all the UI-thread callbacks to handle the case
where the spawning Activity has been destroyed.

~~~java
public class TestActivity extends Activity {

	private static class DoBackgroundTask extends CustomAsyncTask<Void, Integer, Void> {
		private static final String TAG = "DoBackgroundTask";

		private ProgressDialog mProgress;
		private int mCurrProgress;

		public DoBackgroundTask(TestActivity activity) {
			super(activity);
		}

		@Override
		protected void onPreExecute() {
			super.onPreExecute();
			showProgressDialog();
		}

		@Override
		protected void onActivityDetached() {
			if (mProgress != null) {
				mProgress.dismiss();
				mProgress = null;
			}
		}

		@Override
		protected void onActivityAttached() {
			showProgressDialog();
		}

		private void showProgressDialog() {
			mProgress = new ProgressDialog(mActivity);
			mProgress.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
			mProgress.setMessage("Doing stuff...");
			mProgress.setCancelable(true);
			mProgress.setOnCancelListener(new OnCancelListener() {
				@Override
				public void onCancel(DialogInterface dialog) {
					cancel(true);
				}
			});

			mProgress.show();
			mProgress.setProgress(mCurrProgress);
		}

		@Override
		protected Void doInBackground(Void... params) {
			try {
				for (int i = 0; i < 100; i+=10) {
					Thread.sleep(1000);
					this.publishProgress(i);
				}

			}
			catch (InterruptedException e) {
			}

			return null;
		}

		@Override
		protected void onProgressUpdate(Integer... progress) {
			mCurrProgress = progress[0];
			if (mActivity != null) {
				mProgress.setProgress(mCurrProgress);
			}
			else {
				Log.d(TAG, "Progress updated while no Activity was attached.");
			}
		}

		@Override
		protected void onPostExecute(Void result) {
			super.onPostExecute(result);

			if (mActivity != null) {
				mProgress.dismiss();
				Toast.makeText(mActivity, "AsyncTask finished", Toast.LENGTH_LONG).show();
			}
			else {
				Log.d(TAG, "AsyncTask finished while no Activity was attached.");
			}
		}
	}

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        Button b = (Button) findViewById(R.id.launchTaskButton);
        b.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				new DoBackgroundTask(TestActivity.this).execute();
			}
        });
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
    	super.onSaveInstanceState(outState);

    	((CustomApplication) getApplication()).detach(this);
    }

    @Override
    public void onRestoreInstanceState(Bundle savedInstanceState) {
    	super.onRestoreInstanceState(savedInstanceState);

    	((CustomApplication) getApplication()).attach(this);
    }
}
~~~

One of the nice things about this approach is that the Activity does not need
to keep an explicit reference to the AsyncTask. The tasks can be used in a fire
and forget fashion similar to the way it is described in the [official
documentation][2].

The full project is available on github for the curious:
<https://github.com/callorico/CustomAsyncTask>

 [1]: /2011/02/14/android-asynctasks-during-a-screen-rotation-part-i/
 [2]: http://developer.android.com/resources/articles/painless-threading.html
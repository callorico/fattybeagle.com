---
title: The Technical Interview
author: Ryan
layout: post
date: 2007-04-29T21:26:33+00:00
url: /2007/04/29/the-technical-interview/
dsq_thread_id:
  - 235480441
tags:
  - Software

---
Ah, there's nothing quite like the software developer interview. Standing in
front of a whiteboard trying to reason through some design or coding problem is
good times for sure. Thankfully, the majority of the interviewers understand
the general unnaturalness of the interview situation and are more than happy to
throw out hints here and there. Here is a random sampling of the questions that
I've been asked:

**Weeder Questions**

  * What is the difference between deep and shallow copies?
  * What is the difference between abstract classes and interfaces?
  * What is the difference between a struct and a class in C#?
  * When does the garbage collector delete an object?
  * Difference between a vector (ArrayList) and a plain old array? When when
    you use one over the other?
  * Talk about some common data structures. How do they work? Running times?
  * A Patient can have 1 Doctor. How would you model this in a database? Now
    the Patient can have multiple Doctors. How does this change your model?
    Write the SQL to return all the patients for a given doctor.
  * Talk about the model-view-controller pattern.
  * Talk about any design patterns that you have used in a past project.

**More Interesting Questions**

  * Given a uniformly distributed random number generator that returns a value
    between 1 and 5 (inclusive) how can you create a uniformly distributed
    random number generator that returns a value between 1 and 7 (inclusive)?
  * Given two sorted lists of numbers, return a sorted list of numbers with no
    duplicates. What is the running time? Now assume the input lists are not
    sorted.
  * Implement the T9 text prediction software. How would you implement a method
    that returns a set of words corresponding to a number sequence that is
    passed in? Naive implementation running time? Using a preprocessing step,
    how can you improve this? Now I want to order the list of words that are
    displayed by frequency of use. How does this change things? Now I want to
    display all possible completions given the number prefix that is passed in.
    How would you implement this?
  * I have a collection of N records. Each record has a field that we want to
    sort the collection on. This field only has K distinct values where K << N
    (assume these K values exist in a separate collection). How can you sort
    the records in better than O(N log N) time? Now, how can you sort using
    less than O(N) extra space?
  * If the creation of an object is very expensive but it can be reused after
    creation (eg, a DB connection), what should you do? How would you implement
    this object pool? What cases do you need to worry about? Design tradeoffs,
    etc.
  * A movie theater owner comes to you and wants to design a website that
    displays the movies being shown and allow customers to order tickets. How
    would use design this system?
  * Create an application framework for a peer-to-peer system that allows
    connections to be made between arbitrary peers and arbitrary messages to be
    sent between them. No threading allowed so use the select() method to check
    when a socket can be read/written and setup the event loop.

Clearly, the interviewers don't expect you to come up with a complete solution
for some of these. It is more about trying to see how you think so always
remember to verbalize your thought process. The good questions in my opinion
are the more open-ended design questions that allow for lots of little
interesting discussion points about tradeoffs and such. The algorithmic ones on
the other hand usually tend to have some sort of "trick" to them.
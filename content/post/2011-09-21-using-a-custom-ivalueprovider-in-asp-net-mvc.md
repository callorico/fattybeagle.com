---
title: Using a custom IValueProvider in ASP.NET MVC
author: Ryan
layout: post
date: 2011-09-22T04:26:28+00:00
url: /2011/09/21/using-a-custom-ivalueprovider-in-asp-net-mvc/
dsq_thread_id:
  - 422179839
tags:
  - Software

---
I've been working with an ASP.NET MVC application at the day job and I am
impressed at how nicely the framework allows users to modify the behavior of
the out-of-the-box functionality without jumping through ridiculous hoops (I'm
looking at you SharePoint). The MVC team at Microsoft did a nice job of sizing
the Lego pieces appropriately. Kudos!

One of the automagic pieces of functionality that comes with the framework is
the ability to bind http request fields to strongly typed C# objects
automatically via the [DefaultModelBinder][1].

At first glance, creating a custom model binder seemed like a good fit for
taking an encoded set of name/value pairs stored in a hidden input form field
and binding them to a POCO. With this particular application, there is an
external tool that will automatically set the hidden field value using the
following format:

`I've been working with an ASP.NET MVC application at the day job and I am
impressed at how nicely the framework allows users to modify the behavior of
the out-of-the-box functionality without jumping through ridiculous hoops (I'm
looking at you SharePoint). The MVC team at Microsoft did a nice job of sizing
the Lego pieces appropriately. Kudos!

One of the automagic pieces of functionality that comes with the framework is
the ability to bind http request fields to strongly typed C# objects
automatically via the [DefaultModelBinder][1].

At first glance, creating a custom model binder seemed like a good fit for
taking an encoded set of name/value pairs stored in a hidden input form field
and binding them to a POCO. With this particular application, there is an
external tool that will automatically set the hidden field value using the
following format:

`<name>:<value>|<name2>:<value2>`

and then post the form to the server. It would have been nice if this external
tool used a more standard encoding like json but unfortunately this is outside
of our control.

In addition to binding the request data to a POCO, I also wanted to use [data
annotations][2] for validation purposes. However, it seemed like there was a
[fair bit of trickery][3] involved in getting a custom IModelBinder
implementation to perform the validation.

I was about to head down the derived DefaultModelBinder route when I stumbled
across Phil Haacked's [post][4] about IValueProviders. The particularly
important bit is one of the contributions from his co-worker:

> ...value providers provide an abstraction over where values actually come
> from. Value providers are responsible for aggregating the values that are
> part of the current request, e.g. from Form collection, the query string,
> JSON, etc. They basically say “I don’t know what a ‘FirstName’ is for or what
> you can do with it, but if you ask me for a ‘FirstName’ I can give you what I
> have.”

Eureka! I decided that a much simpler solution would be to create a custom
IValueProvider that parses the encoded name/value pairs in the hidden field and
presents a dictionary to the plain ole' DefaultModelProvider. That way, we get
all the DataAnnotation validation goodness for free. This turned out to be
really easy to do:

~~~csharp
public class EncodedDataValueProviderFactory : ValueProviderFactory
{
    public override IValueProvider GetValueProvider(ControllerContext controllerContext)
    {
        String rawCallData = controllerContext.HttpContext.Request.Form["encoded_data"];
        NameValueCollection nameValues = new NameValueCollection();
        if (!String.IsNullOrWhiteSpace(rawCallData))
        {
            var q = from nvp in rawCallData.Split(new char[] {'|'}, StringSplitOptions.RemoveEmptyEntries)
                    let tokens = nvp.Split(':')
                    where tokens.Length == 2
                    select new
                    {
                        Name = tokens[0],
                        Value = tokens[1]
                    };

            foreach (var pair in q)
            {
                nameValues.Add(pair.Name, pair.Value);
            }
        }

        return new NameValueCollectionValueProvider(nameValues, CultureInfo.CurrentCulture);
    }
}
~~~

I decided to delegate to the out-of-the-box
[NameValueCollectionValueProvider][5] instead of rolling my own IValueProvider.

Then, the EncodedDataValueProviderFactory simply needs to be registered in the
Application_Start even in the Global.asax.cs class:

~~~csharp
protected void Application_Start()
{
    ValueProviderFactories.Factories.Add(new EncodedDataValueProviderFactory());
}
~~~

That's it! The DefaultModelBinder will automatically query the new value
provider when it attempts to bind values to the POCO.

 [1]: http://msdn.microsoft.com/en-us/library/system.web.mvc.defaultmodelbinder.aspx
 [2]: http://weblogs.asp.net/scottgu/archive/2010/01/15/asp-net-mvc-2-model-validation.aspx
 [3]: http://stackoverflow.com/questions/5820637/custom-model-binding-model-state-and-data-annotations
 [4]: http://haacked.com/archive/2011/06/30/whatrsquos-the-difference-between-a-value-provider-and-model-binder.aspx
 [5]: http://msdn.microsoft.com/en-us/library/system.web.mvc.namevaluecollectionvalueprovider.aspx
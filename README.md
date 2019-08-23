# Challenge #11

There is an app which enables users to find pubs in their local area and find detailed information about each pub. The app obtains information about pubs using a webservice that scrapes information from websites and returns pub information formatted into json. Pub details don't change very often so the webservice caches detailed pub information to a database to improve performance. The webservice stores the raw json that is returned by the webservice along with a create-timestamp.  

Over time the cache has become a database of historical pub information, albeit in inconvenient json form. As its a cache, its not complete or up to date but could still be useful. 

The objective of this challenge is to create a function called __obtainListOfBeers__ to convert json listing each pub within an area into json listing different types of beer available in the same area. This will form part of a new experimental webservice that will show types of beer available within a given area, and which pub serves each beer. 

The json input into __obtainListOfBeers__  will be a string with the following content:

```json
{  
   "Pubs":[  
      {  
         "Name":"Cask and Glass",
         "PostCode":"SW1E 5HN",
         "RegularBeers":[  
            "Shepherd Neame Master Brew",
            "Shepherd Neame Spitfire"
         ],
         "GuestBeers":[  
            "Shepherd Neame --seasonal--",
            "Shepherd Neame --varies--",
            "Shepherd Neame Whitstable Bay Pale Ale"
         ],
         "PubService":"https://pubcrawlapi.appspot.com/pub/?v=1&id=15938&branch=WLD&uId=mike&pubs=no&realAle=yes&memberDiscount=no&town=London",
         "Id":"15938",
         "Branch":"WLD",
         "CreateTS":"2019-05-16 19:31:39",
         ...<lots of other fields which can be ignored>...
      },
      ...<other pubs>...
   ]
}
```

These fields in the input json are mandatory: _Name_, _Id_, _Branch_, _CreateTS_ and _PubService_. Any other fields are optional, including _RegularBeers_ and _GuestBeers_. All beers served in each pub are listed under RegularBeers and GuestBeers on the input json. Some pubs will be duplicated and in that case only include the pub with the highest CreateTS (_Id_ and _Branch_ combined form the unique key for each pub). 

The list of beers returned by __obtainListOfBeers__ should contain beers in alphabetic order. The format of the list is up to you and will depend on the programming language you use; you don't need to convert the list into a string containing json. Each beer record in the list  should include the following information about each beer:

* Name: A string showing the name of the beer

* PubName: A string showing the name of the pub serving the beer (called Name on the input json).

* PubService: A strng copied form the input json.

* RegularBeer: Boolean set true if the beer is listed as a RegularBeer and false if the beer is listed as a GuestBeer on the input json.


A beer may be in more than one pub, in which case add a separate record to the list for each pub the beer is in.
Sample json can be obtained from https://pubcrawlapi.appspot.com/pubcache/?uId=mike&lng=-0.141499&lat=51.496466&deg=0.003. You can change the lng and lat and deg in the query param to find pubs in the pubchache in any part of the UK (lng and lat are geolocation co-ordinates and deg gives a range in degrees with 1 degree equal to approx 70 miles).  

Closing date is 2/9/2019

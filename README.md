## fitgrapher

Fitgrapher is Ruby on Rails App which consumes fitbit data.

To setup your own instance of fitgrapher, clone the repository, and then create a file called `config/fitgem.yml`. Go to http://dev.fitbit.com/ and create a fitbit application. Go to your app's details page and copy the consumer key and secret into `config/fitgem.yml`:

``` yaml
:oauth:
  :consumer_key: YOUR_CONSUMER_KEY
  :consumer_secret: YOUR_CONSUMER_SECRET
```

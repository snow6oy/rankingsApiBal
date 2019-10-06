# rankingsApiBal

An API written in Ballerina that returns website rankings

```
$ curl http://localhost:9090/rankings/?query=goo
[{
  "rank": "1",
  "domain": "google.com"
 }, {
  "rank": "7",
  "domain": "google.co.in"
 }]
```
The data is sourced from [Alexa](https://www.alexa.com/).

# docker

The Ballinerina API module builds a [docker image](https://hub.docker.com/r/snow6oy/pacheco/tags). Once pulled it can be run as.

```
> docker run -d -p 9090:9090 snow6oy/pacheco:rankings
$CONTAINER

> curl http://localhost:9090/rankings/status
ok
```

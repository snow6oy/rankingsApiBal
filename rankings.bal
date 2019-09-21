//package net.fnarg.api;

import ballerina/http;
import ballerina/log;
import ballerina/io;

service rankings on new http:Listener(9090) {
  resource function listRankings(http:Caller caller, http:Request req) {

//private final String query = new String();
//public List<Rankings> ranking(@RequestParam(value="query", defaultValue="facebook.com") String query) {
//List<Rankings> rank = repository.findByDomainStartingWith(query);

    string? q = req.getQueryParamValue("query");
    io:println("searching for ", q);

    var result = caller->respond("search result");
    if (result is error) {
      log:printError("Error sending response", result);
    }
  }
}

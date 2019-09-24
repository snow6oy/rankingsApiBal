//package net.fnarg.api;

import ballerina/http;
import ballerina/log;
import ballerina/io;

type Ranking record {
  string rank;
  string domain;
};

service rankings on new http:Listener(9090) {
  resource function list(http:Caller caller, http:Request req) {
    //error? out = searchDomains(req.getQueryParamValue("query"));
    table<Ranking>|error domains = searchDomains(req.getQueryParamValue("query"));
    if (domains is table<Ranking>) {
      io:println(domains);
      json|error j = json.constructFrom(domains);
      //json j = check <json>domains;
      io:println(j);
      var result = caller->respond("domains");
      if (result is error) {
        log:printError("Error sending response", result);
      }
    } else {
      log:printError("Error loading result", domains);
    }
  }
}

//public List<Rankings> ranking(@RequestParam(value="query", defaultValue="facebook.com") String query) {
//function searchDomains(string? query) returns @tainted error? {
function searchDomains(string? query) returns @tainted table<Ranking>|error {

  string srcFileName = "./top-10.csv";
  string q;
  table<Ranking> rs = table {{ key rank, domain }}; // empty 
  if (query is string) {
    q = query;
  } else { // fallback to something TODO this in func sig
    q = "facebook.com";
  }
  io:ReadableCSVChannel csvChannel = check io:openReadableCsvFile(srcFileName);
  var database = csvChannel.getTable(Ranking);   
  var ignoreCsvClose = csvChannel.close();
  io:println("searching for ", q);

  if (database is table<Ranking>) {
    foreach var rec in database {
      if (domainMatches(rec.domain, q)) {
        Ranking result = { rank: rec.rank, domain: rec.domain };
        var ignoreTableError = rs.add(result); // ignore outcome because only a copy
      }
    }
    database = rs; 
  } else {
    log:printError(
      "An error occurred while creating table: ", err = database
    );
  }
  return database;
}

function domainMatches(string domain, string query) returns boolean {
  // io:println(domain, "\t", query);
  boolean matched = false;
  int? index = domain.indexOf(query);
  if (index is int) {
    matched = true;
  } 
  return matched;
}

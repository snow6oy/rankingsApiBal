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
    error? out = searchDomains(req.getQueryParamValue("query"));
    var result = caller->respond("search result");
    if (result is error) {
      log:printError("Error sending response", result);
    }
  }
}

//public List<Rankings> ranking(@RequestParam(value="query", defaultValue="facebook.com") String query) {
function searchDomains(string? query) returns @tainted error? {

  string q = "facebook.com";
  //q = query;
  
  string srcFileName = "./top-10.csv";
  io:println("searching for ", q);

  io:ReadableCSVChannel csvChannel = check io:openReadableCsvFile(srcFileName);
  //  io:println("Reading  " + srcFileName + " as a table");
  var database = csvChannel.getTable(Ranking);
  table<Ranking> rs = table {{ key rank, domain }};

  if (database is table<Ranking>) {
    foreach var rec in database {
      boolean dm = domainMatches(rec.domain, q);

      if (dm) {
        // io:println("Found a match\n", rec.domain);
        Ranking result = { rank: rec.rank, domain: rec.domain };
        var ignoreTableError = rs.add(result); // ignore outcome because only a copy
      }
    }
  } else {
    log:printError(
      "An error occurred while creating table: ", err = database
    );
  }
  var ignoreCsvClose = csvChannel.close();
  io:println(rs);
  return ignoreCsvClose;
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

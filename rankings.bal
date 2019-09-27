import ballerina/jsonutils;
import ballerina/http;
import ballerina/log;
import ballerina/io;

type Ranking record {
  string rank;
  string domain;
};

service rankings on new http:Listener(9090) {
  @http:ResourceConfig {
    methods: ["GET"],
    path: "/"
  }
  resource function list(http:Caller caller, http:Request req) {
    http:Response r = new;
    table<Ranking>|error domains = searchDomains(req.getQueryParamValue("query"));
    if (domains is table<Ranking>) {
      json payload = jsonutils:fromTable(domains);
      r.setJsonPayload(<@untainted> payload);
      var result = caller->respond(r);
      if (result is error) {
        log:printError("Error sending response", result);
      }
    } else {
      log:printError("Error loading result", domains);
    }
  }
}

function searchDomains(string? query) returns @tainted table<Ranking>|error {

  string srcFileName = "./top-1m.csv";
  string q = query is string ? query : "facebook.com";
  table<Ranking> rs = table {{ key rank, domain }}; // empty 
  io:ReadableCSVChannel csvChannel = check io:openReadableCsvFile(srcFileName);
  var database = csvChannel.getTable(Ranking);   
  var ignoreCsvClose = csvChannel.close();
  // io:println("searching for ", q);

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

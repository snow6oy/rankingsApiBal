import ballerina/io;
import ballerina/log;

type Ranking record {
  string rank;
  string domain;
};

public function main() returns error? {
  string srcFileName = "./top-10.csv";
  string query = "google";

  io:ReadableCSVChannel csvChannel = check io:openReadableCsvFile(srcFileName);
  //  io:println("Reading  " + srcFileName + " as a table");
  var database = csvChannel.getTable(Ranking);
  table<Ranking> rs = table {{ key rank, domain }};

  if (database is table<Ranking>) {
    foreach var rec in database {
      if (domainMatches(rec.domain, query)) {
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

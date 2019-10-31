import ballerina/io;

type Ranking record {
  string rank;
  string domain;
};

table<Ranking> database = table{};

function __init() returns error? {
  io:println("initialising database");
  string srcFileName = "src/rankingsApiBal/resources/top-10.csv";
  io:ReadableCSVChannel csvChannel = check io:openReadableCsvFile(srcFileName);
  var anyTable = csvChannel.getTable(Ranking); 
  if (anyTable is table<Ranking>) {
    database = <@untainted> anyTable;
    io:println("ok");
  } else {
    io:println("Error initialising database", anyTable);
  }
  var ignoreCsvClose = csvChannel.close();
}

function searchDomains(string? query) returns @tainted table<Ranking>|error {
  string q = query is string ? query : "facebook.com";
  io:println("searching for ", query);
  table<Ranking> rs = table {{ key rank, domain }};
  foreach var rec in database {
    if (domainMatches(rec.domain, q)) {
      Ranking result = { rank: rec.rank, domain: rec.domain };
      var ignoreTableError = rs.add(result); // ignore outcome because only a copy
    }
  }
  return rs;
}

function domainMatches(string domain, string query) returns boolean {
  boolean matched = false;
  int? index = domain.indexOf(query);
  if (index is int) {
    matched = true;
  } 
  return matched;
}

import ballerina/jsonutils;
import ballerina/http;
import ballerina/log;

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

import ballerina/docker;
import ballerina/jsonutils;
import ballerina/http;
import ballerina/log;

@docker:Expose {}
listener http:Listener endpoint = new(9090);

@docker:Config {
  name: "snow6oy/pacheco",
  tag: "rankings"
}

@docker:CopyFiles {
  files: [{ 
    sourceFile: "src/rankingsApiBal/resources/top-1m.csv", 
    target: "/home/ballerina/src/rankingsApiBal/resources/top-1m.csv" 
  }]
}

@http:ServiceConfig {
  basePath: "/rankings"
}

service rankings on endpoint {
  @http:ResourceConfig {
    methods: ["GET"],
    path: "/"
  }
  resource function search(http:Caller caller, http:Request request) {
    http:Response response = new;
    table<Ranking>|error domains = searchDomains(request.getQueryParamValue("query"));
    if (domains is table<Ranking>) {
      json payload = jsonutils:fromTable(domains);
      response.setJsonPayload(<@untainted> payload);
      var result = caller->respond(response);
      if (result is error) {
        log:printError("Error sending response", result);
      }
    } else {
      log:printError("Error generating payload", domains);
    }
  }
  @http:ResourceConfig {
    methods: ["GET"],
    path: "/status"
  }
  resource function status(http:Caller caller, http:Request request) {
    http:Response response = new;
    response.setTextPayload("ok\n");
    var responseResult = caller->respond(response);
    if (responseResult is error) {
      error err = responseResult;
      log:printError("Error sending response", err);
    }
  }
}

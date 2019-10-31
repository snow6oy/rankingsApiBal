import ballerina/kubernetes;
import ballerina/jsonutils;
import ballerina/http;
import ballerina/log;

@kubernetes:Service {
  serviceType: "NodePort"
}

@kubernetes:Ingress {
  hostname: "fnarg.net"
}

listener http:Listener rankings = new(9090, config = {
  secureSocket: {
    keyStore: {
      path: "src/rankingsApiBal/resources/ballerinaKeystore.p12",
      password: "ballerina"
    },
    trustStore: {
      path: "src/rankingsApiBal/resources/ballerinaTruststore.p12",
      password: "ballerina"
    }
  }
});

@kubernetes:Deployment {
  livenessProbe: true,
  image: "snow6oy/fnarg:rankingsApiBal-v1",
  copyFiles: [{ 
    sourceFile: "src/rankingsApiBal/resources/top-10.csv", 
    target: "/home/ballerina/src/rankingsApiBal/resources/top-10.csv" 
  }]
}

@http:ServiceConfig {
  basePath: "/rankings"
}

service r on rankings {
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

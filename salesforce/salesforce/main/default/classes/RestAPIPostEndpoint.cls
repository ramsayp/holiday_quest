@RestResource(urlMapping='/restAPIPostEndpoint')
global with sharing class RestAPIPostEndpoint {

    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // CORS headers
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Access-Control-Allow-Methods', 'POST');
        res.addHeader('Access-Control-Allow-Headers', 'Content-Type, Accept, Origin');
        res.addHeader('Content-Type', 'application/json');

        try {
            String jsonBody = '';

            // Try reading from request body first
            if (req.requestBody != null && req.requestBody.size() > 0) {
                jsonBody = req.requestBody.toString();
            }

            // Fall back to 'body' form parameter (for simple requests)
            if (String.isBlank(jsonBody)) {
                jsonBody = req.params.get('body');
            }

            if (String.isBlank(jsonBody)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error":"Empty request body"}');
                return;
            }

            Map<String, Object> requestMap =
                (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

            String type = (String) requestMap.get('type');
            Object payload = requestMap.get('payload');

            if (type == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error":"Missing type field"}');
                return;
            }

            RestAPIPostInterface handler = RestAPIPostFactory.getHandler(type);

            if (handler == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error":"Unsupported type: ' + type + '"}');
                return;
            }

            Map<String, Object> result = handler.process(payload);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(result));

        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error":"' + e.getMessage() + '"}');
        }
    }
}
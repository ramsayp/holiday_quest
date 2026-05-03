global interface RestAPIPostInterface {

    // All REST POST handlers must implement this method.
    // It receives the request payload and returns a response map.
    // The returned Map will later be serialized into JSON for the API response.
    Map<String, Object> process(Object payload);
}
global without sharing class HQ_RemovePlaceHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String placeId = (String) data.get('placeId');
 
        if (placeId == null) {
            return new Map<String, Object>{ 'error' => 'Missing placeId' };
        }
 
        List<Place__c> places = [SELECT Id FROM Place__c WHERE Id = :placeId LIMIT 1];
        if (places.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Place not found' };
        }
 
        try {
            delete places[0];
        } catch (DmlException e) {
            return new Map<String, Object>{ 'error' => 'Could not delete: ' + e.getMessage() };
        }
 
        return new Map<String, Object>{ 'success' => true };
    }
}
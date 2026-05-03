// ─────────────────────────────────────────────────────────────────
// HQ_UpdatePlaceHandler.cls
// Payload: { placeId, name, points, category }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_UpdatePlaceHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String placeId = (String) data.get('placeId');
 
        List<Place__c> places = [
            SELECT Id, Name, Points__c, Category__c
            FROM Place__c WHERE Id = :placeId LIMIT 1
        ];
        if(places.isEmpty()) return new Map<String, Object>{ 'error' => 'Place not found' };
 
        Place__c p = places[0];
        if(data.get('name')     != null) p.Name       = (String)  data.get('name');
        if(data.get('points')   != null) p.Points__c  = (Decimal) data.get('points');
        if(data.get('category') != null) p.Category__c= (String)  data.get('category');
        update p;
 
        return new Map<String, Object>{ 'success' => true };
    }
}
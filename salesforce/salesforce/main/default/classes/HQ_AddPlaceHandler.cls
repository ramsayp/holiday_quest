// ─────────────────────────────────────────────────────────────────
// HQ_AddPlaceHandler.cls
// Payload: { holidayId, name, category, points }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_AddPlaceHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
 
        Place__c p = new Place__c(
            Name       = (String)  data.get('name'),
            Category__c = (String) data.get('category'),
            Points__c  = (Decimal) data.get('points'),
            Holiday__c = (String)  data.get('holidayId')
        );
        insert p;
 
        return new Map<String, Object>{
            'success' => true,
            'placeId' => p.Id
        };
    }
}
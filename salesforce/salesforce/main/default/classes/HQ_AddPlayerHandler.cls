// ─────────────────────────────────────────────────────────────────
// HQ_AddPlayerHandler.cls
// Payload: { holidayId, name, color, isAdmin }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_AddPlayerHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;

        Player__c p = new Player__c(
            Name        = (String)  data.get('name'),
            Color__c    = (String)  data.get('color'),
            Is_Admin__c = (Boolean) data.get('isAdmin'),
            Holiday__c  = (String)  data.get('holidayId'),
            Client__c   = (String)  data.get('clientId')
        );
        insert p;

        return new Map<String, Object>{
            'success'  => true,
            'playerId' => p.Id
        };
    }
}
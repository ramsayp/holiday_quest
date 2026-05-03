// ─────────────────────────────────────────────────────────────────
// HQ_UpdatePlayerHandler.cls
// Payload: { playerId, name, color }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_UpdatePlayerHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String playerId = (String) data.get('playerId');
        Player__c p = [SELECT Id, Name, Color__c FROM Player__c WHERE Id = :playerId LIMIT 1];
        if (data.get('name')  != null) p.Name     = (String) data.get('name');
        if (data.get('color') != null) p.Color__c = (String) data.get('color');
        update p;
        return new Map<String, Object>{ 'success' => true };
    }
}
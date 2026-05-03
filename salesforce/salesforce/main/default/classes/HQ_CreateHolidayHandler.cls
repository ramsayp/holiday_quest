// ─────────────────────────────────────────────────────────────────
// HQ_CreateHolidayHandler.cls
// Payload: { clientId, name }
// Creates a Holiday__c and an admin Player__c for the creator
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_CreateHolidayHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String clientId = (String) data.get('clientId');
        String name     = (String) data.get('name');
 
        if (clientId == null || name == null) {
            return new Map<String, Object>{ 'error' => 'Missing clientId or name' };
        }
 
        // Get client name for the player record
        List<Client__c> clients = [
            SELECT Id, Name
            FROM Client__c
            WHERE Id = :clientId
            LIMIT 1
        ];
        if (clients.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Client not found' };
        }
 
        // Create the holiday
        Holiday__c h = new Holiday__c(
            Name       = name,
            Client__c  = clientId,
            Wrapped__c = false
        );
        insert h;
 
        // Auto-create admin player for the creator
        Player__c p = new Player__c(
            Name        = clients[0].Name,
            Holiday__c  = h.Id,
            Client__c   = clientId,
            Is_Admin__c = true,
            Color__c    = '#7B5E9C'
        );
        insert p;
 
        return new Map<String, Object>{
            'success'   => true,
            'holidayId' => h.Id,
            'playerId'  => p.Id,
            'name'      => h.Name
        };
    }
}
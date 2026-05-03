// ─────────────────────────────────────────────────────────────────
// HQ_GetMyHolidaysHandler.cls
// Payload: { clientId }
// Returns all holidays where this client has a Player record
// Tagged as 'created' (admin) or 'invited' (non-admin)
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_GetMyHolidaysHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String clientId = (String) data.get('clientId');
 
        if (clientId == null) {
            return new Map<String, Object>{ 'error' => 'Missing clientId' };
        }
 
        List<Player__c> players = [
            SELECT Id, Holiday__c, Holiday__r.Name, Holiday__r.Wrapped__c,
                   Is_Admin__c, Color__c
            FROM Player__c
            WHERE Client__c = :clientId
            ORDER BY Holiday__r.CreatedDate DESC
        ];
 
        List<Map<String, Object>> holidays = new List<Map<String, Object>>();
        for (Player__c p : players) {
            holidays.add(new Map<String, Object>{
                'holidayId' => p.Holiday__c,
                'name'      => p.Holiday__r.Name,
                'wrapped'   => p.Holiday__r.Wrapped__c,
                'tag'       => p.Is_Admin__c ? 'created' : 'invited',
                'playerId'  => p.Id,
                'isAdmin'   => p.Is_Admin__c,
                'color'     => p.Color__c
            });
        }
 
        return new Map<String, Object>{
            'success'  => true,
            'holidays' => holidays
        };
    }
}
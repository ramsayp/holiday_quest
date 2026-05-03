// ─────────────────────────────────────────────────────────────────
// CheckEmailHandler.cls
// Payload: { email }
// Public route — checks if email exists and what state it's in
// Used by app to decide which screen to show
// ─────────────────────────────────────────────────────────────────
global without sharing class CheckEmailHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String email = (String) data.get('email');
 
        if (email == null) {
            return new Map<String, Object>{ 'error' => 'Missing email' };
        }
 
        List<Client__c> clients = [
            SELECT Id, Is_Placeholder__c
            FROM Client__c
            WHERE Email__c = :email
            LIMIT 1
        ];
 
        if (clients.isEmpty()) {
            return new Map<String, Object>{ 'exists' => false };
        }
 
        return new Map<String, Object>{
            'exists'        => true,
            'isPlaceholder' => clients[0].Is_Placeholder__c
        };
    }
}
// ─────────────────────────────────────────────────────────────────
// VerifyClientHandler.cls
// Payload: { email, passwordHash }
// Rejects placeholder accounts with a helpful message
// ─────────────────────────────────────────────────────────────────
global without sharing class VerifyClientHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String email    = (String) data.get('email');
        String passHash = (String) data.get('passwordHash');
 
        if (email == null || passHash == null) {
            return new Map<String, Object>{ 'error' => 'Missing email or password' };
        }
 
        // Query by email only — compare hash in Apex to avoid FLS issues
        List<Client__c> clients = [
            SELECT Id, Name, Email__c, Password_Hash__c, Is_Placeholder__c
            FROM Client__c
            WHERE Email__c = :email
            LIMIT 1
        ];
 
        if (clients.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Email or password incorrect' };
        }
 
        Client__c c = clients[0];
 
        // Placeholder account — needs to set password first
        if (c.Is_Placeholder__c) {
            return new Map<String, Object>{
                'error'       => 'Please set up your account first',
                'isPlaceholder' => true,
                'email'       => c.Email__c
            };
        }
 
        // Verify password hash
        if (c.Password_Hash__c != passHash) {
            return new Map<String, Object>{ 'error' => 'Email or password incorrect' };
        }
 
        return new Map<String, Object>{
            'success'  => true,
            'clientId' => c.Id,
            'name'     => c.Name,
            'email'    => c.Email__c
        };
    }
}
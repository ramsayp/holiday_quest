// ─────────────────────────────────────────────────────────────────
// CreateClientHandler.cls
// Payload: { name, email, passwordHash }
// Handles 3 cases:
//   1. Email exists as full client → error (already registered)
//   2. Email exists as placeholder → convert to full account
//   3. Email not found → create new full client
// ─────────────────────────────────────────────────────────────────
global without sharing class CreateClientHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String name     = (String) data.get('name');
        String email    = (String) data.get('email');
        String passHash = (String) data.get('passwordHash');
 
        if (name == null || email == null || passHash == null) {
            return new Map<String, Object>{ 'error' => 'Missing required fields' };
        }
 
        List<Client__c> existing = [
            SELECT Id, Name, Email__c, Is_Placeholder__c
            FROM Client__c
            WHERE Email__c = :email
            LIMIT 1
        ];
 
        if (!existing.isEmpty()) {
            Client__c c = existing[0];
 
            // Already a full account
            if (!c.Is_Placeholder__c) {
                return new Map<String, Object>{ 'error' => 'Email already registered' };
            }
 
            // Placeholder exists — convert to full account
            c.Name              = name;
            c.Password_Hash__c  = passHash;
            c.Is_Placeholder__c = false;
            update c;
 
            return new Map<String, Object>{
                'success'     => true,
                'clientId'    => c.Id,
                'name'        => c.Name,
                'email'       => c.Email__c,
                'wasPlaceholder' => true
            };
        }
 
        // New client
        Client__c c = new Client__c(
            Name              = name,
            Email__c          = email,
            Password_Hash__c  = passHash,
            Is_Placeholder__c = false
        );
        try {
            insert c;
        } catch (DmlException e) {
            // Unique constraint on Email__c — email already registered
            if (e.getMessage().contains('duplicate') || e.getMessage().contains('DUPLICATE')) {
                return new Map<String, Object>{ 'error' => 'Email already registered' };
            }
            return new Map<String, Object>{ 'error' => e.getMessage() };
        }
 
        return new Map<String, Object>{
            'success'     => true,
            'clientId'    => c.Id,
            'name'        => c.Name,
            'email'       => c.Email__c,
            'wasPlaceholder' => false
        };
    }
}
// ─────────────────────────────────────────────────────────────────
// SetupAccountHandler.cls
// Payload: { email, name, passwordHash }
// Converts a placeholder account to a full account
// ─────────────────────────────────────────────────────────────────
global without sharing class SetupAccountHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String email    = (String) data.get('email');
        String name     = (String) data.get('name');
        String passHash = (String) data.get('passwordHash');
 
        if (email == null || passHash == null || name == null) {
            return new Map<String, Object>{ 'error' => 'Missing required fields' };
        }
 
        List<Client__c> clients = [
            SELECT Id, Name, Email__c, Is_Placeholder__c
            FROM Client__c
            WHERE Email__c = :email
            LIMIT 1
        ];
 
        if (clients.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Account not found' };
        }
 
        Client__c c = clients[0];
 
        if (!c.Is_Placeholder__c) {
            return new Map<String, Object>{ 'error' => 'Account already set up' };
        }
 
        // Store old name so we can find Player records to update
        String oldName = c.Name;
 
        // Convert to full account
        c.Name              = name;
        c.Password_Hash__c  = passHash;
        c.Is_Placeholder__c = false;
        update c;
 
        // Update all Player records for this client
        // If the player name still matches the old placeholder name (set by admin),
        // update it to Kim's chosen name. If admin already customised it differently,
        // leave it — admin can still edit via admin panel.
        List<Player__c> players = [
            SELECT Id, Name FROM Player__c WHERE Client__c = :c.Id
        ];
        List<Player__c> toUpdate = new List<Player__c>();
        for (Player__c p : players) {
            // Update if name matches old placeholder name or old email-as-name
            if (p.Name == oldName || p.Name == c.Email__c || p.Name == 'Invited Player') {
                p.Name = name;
                toUpdate.add(p);
            }
        }
        if (!toUpdate.isEmpty()) update toUpdate;
 
        return new Map<String, Object>{
            'success'  => true,
            'clientId' => c.Id,
            'name'     => c.Name,
            'email'    => c.Email__c
        };
    }
}
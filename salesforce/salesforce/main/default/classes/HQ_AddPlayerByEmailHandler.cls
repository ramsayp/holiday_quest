// ─────────────────────────────────────────────────────────────────
// HQ_AddPlayerByEmailHandler.cls
// Payload: { holidayId, email, color }
// Journey 1: Client found, full account → create Player
// Journey 2: Client found, placeholder → create Player (they'll set up later)
// Journey 3: No Client found → create placeholder Client + Player
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_AddPlayerByEmailHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String holidayId = (String) data.get('holidayId');
        String email     = (String) data.get('email');
        String color     = (String) data.get('color');
 
        if (holidayId == null || email == null) {
            return new Map<String, Object>{ 'error' => 'Missing holidayId or email' };
        }
 
        // Look up client by email
        List<Client__c> clients = [
            SELECT Id, Name, Is_Placeholder__c
            FROM Client__c
            WHERE Email__c = :email
            LIMIT 1
        ];
 
        Client__c c;
        Boolean wasCreated = false;
 
        if (clients.isEmpty()) {
            // No client — create placeholder
            // Use admin name if provided, otherwise email as temp name
            String placeholderName = String.isNotBlank((String)data.get('name')) ? (String)data.get('name') : email;
            c = new Client__c(
                Name              = placeholderName,
                Email__c          = email,
                Is_Placeholder__c = true
            );
            try {
                insert c;
            } catch (DmlException e) {
                // Race condition — someone registered between our query and insert
                // Re-query to get the existing record
                List<Client__c> recheck = [
                    SELECT Id, Name, Is_Placeholder__c FROM Client__c WHERE Email__c = :email LIMIT 1
                ];
                if (!recheck.isEmpty()) {
                    c = recheck[0];
                } else {
                    return new Map<String, Object>{ 'error' => 'Could not create account: ' + e.getMessage() };
                }
            }
            wasCreated = true;
        } else {
            c = clients[0];
        }
 
        // Check not already a player on this holiday
        List<Player__c> existing = [
            SELECT Id FROM Player__c
            WHERE Client__c = :c.Id
            AND Holiday__c = :holidayId
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'This person is already on this holiday' };
        }
 
        // Get holiday name for the response
        List<Holiday__c> holidays = [
            SELECT Id, Name FROM Holiday__c WHERE Id = :holidayId LIMIT 1
        ];
        String holidayName = holidays.isEmpty() ? '' : holidays[0].Name;
 
        // Determine player name
        // Full account: use their registered name
        // Placeholder: use admin name if provided, otherwise placeholder client name
        String adminName = (String) data.get('name');
        String playerName;
        if (!c.Is_Placeholder__c) {
            playerName = c.Name;
        } else {
            playerName = String.isNotBlank(adminName) ? adminName : c.Name;
        }
 
        // Create player
        Player__c p = new Player__c(
            Name        = playerName,
            Holiday__c  = holidayId,
            Client__c   = c.Id,
            Is_Admin__c = false,
            Color__c    = color != null ? color : '#3D9BB5'
        );
        insert p;
 
        return new Map<String, Object>{
            'success'       => true,
            'playerId'      => p.Id,
            'playerName'    => p.Name,
            'clientId'      => c.Id,
            'isPlaceholder' => c.Is_Placeholder__c,
            'wasCreated'    => wasCreated,
            'holidayName'   => holidayName,
            'email'         => email
        };
    }
}
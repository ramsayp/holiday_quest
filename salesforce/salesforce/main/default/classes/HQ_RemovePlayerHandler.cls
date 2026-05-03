global without sharing class HQ_RemovePlayerHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String playerId = (String) data.get('playerId');
 
        if (playerId == null) {
            return new Map<String, Object>{ 'error' => 'Missing playerId' };
        }
 
        List<Player__c> players = [SELECT Id FROM Player__c WHERE Id = :playerId LIMIT 1];
        if (players.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Player not found' };
        }
 
        try {
            delete players[0];
        } catch (DmlException e) {
            return new Map<String, Object>{ 'error' => 'Could not delete: ' + e.getMessage() };
        }
 
        return new Map<String, Object>{ 'success' => true };
    }
}
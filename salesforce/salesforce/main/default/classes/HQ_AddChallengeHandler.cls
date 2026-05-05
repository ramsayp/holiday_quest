// ─────────────────────────────────────────────────────────────────
// HQ_AddChallengeHandler.cls
// Payload: { holidayId, playerId, name, notes (optional), placeId (optional) }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_AddChallengeHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;

        String name      = (String) data.get('name');
        String holidayId = (String) data.get('holidayId');
        String playerId  = (String) data.get('playerId');

        if (name == null || holidayId == null || playerId == null) {
            return new Map<String, Object>{ 'error' => 'Missing required fields' };
        }

        Challenge__c c = new Challenge__c(
            Name          = name,
            Holiday__c    = holidayId,
            Created_By__c = playerId,
            Notes__c      = (String) data.get('notes'),
            Place__c      = (String) data.get('placeId')
        );
        insert c;

        return new Map<String, Object>{
            'success'     => true,
            'challengeId' => c.Id
        };
    }
}

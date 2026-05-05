// ─────────────────────────────────────────────────────────────────
// HQ_CreateCheckinHandler.cls
// Payload: { playerId, placeId, taggedById }
// taggedById = null means the player checked themselves in
// taggedById = a player Id means someone tagged them
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_CreateCheckinHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
 
        String playerId        = (String) data.get('playerId');
        String placeId         = (String) data.get('placeId');
        String taggedById      = (String) data.get('taggedById');
        String parentCheckinId = (String) data.get('parentCheckinId');
        Boolean allowRepeat    = data.get('allowRepeat') == true;

        if (playerId == null || placeId == null) {
            return new Map<String, Object>{ 'error' => 'Missing playerId or placeId' };
        }

        if (!allowRepeat) {
            List<Checkin__c> existing = [
                SELECT Id FROM Checkin__c
                WHERE Player__c = :playerId
                AND Place__c = :placeId
                LIMIT 1
            ];
            if (!existing.isEmpty()) {
                return new Map<String, Object>{ 'error' => 'Already checked in' };
            }
        }

        Checkin__c c = new Checkin__c(
            Player__c         = playerId,
            Place__c          = placeId,
            Tagged_By__c      = taggedById,
            Parent_Checkin__c = parentCheckinId
        );
        insert c;

        // Return the new checkin with timestamp so app can update immediately
        Checkin__c inserted = [
            SELECT Id, Player__c, Place__c, Tagged_By__c, Parent_Checkin__c, CreatedDate
            FROM Checkin__c
            WHERE Id = :c.Id
        ];
 
        return new Map<String, Object>{
            'success'    => true,
            'checkin'    => new Map<String, Object>{
                'id'              => inserted.Id,
                'playerId'        => inserted.Player__c,
                'placeId'         => inserted.Place__c,
                'taggedById'      => inserted.Tagged_By__c,
                'parentCheckinId' => inserted.Parent_Checkin__c,
                'isTag'           => inserted.Tagged_By__c != null,
                'timestamp'       => inserted.CreatedDate.getTime()
            }
        };
    }
}
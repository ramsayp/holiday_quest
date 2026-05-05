// ─────────────────────────────────────────────────────────────────
// HQ_CreateChallengeCheckinHandler.cls
// Payload: { challengeId, playerId }
// One check-in per player per challenge — rejects duplicates.
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_CreateChallengeCheckinHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;

        String challengeId = (String) data.get('challengeId');
        String playerId    = (String) data.get('playerId');

        if (challengeId == null || playerId == null) {
            return new Map<String, Object>{ 'error' => 'Missing required fields' };
        }

        List<Challenge_Checkin__c> existing = [
            SELECT Id FROM Challenge_Checkin__c
            WHERE Challenge__c = :challengeId AND Player__c = :playerId
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Already checked in to this challenge' };
        }

        Challenge_Checkin__c cc = new Challenge_Checkin__c(
            Challenge__c = challengeId,
            Player__c    = playerId
        );
        insert cc;

        return new Map<String, Object>{
            'success'          => true,
            'challengeCheckinId' => cc.Id
        };
    }
}

// ─────────────────────────────────────────────────────────────────
// HQ_RemoveChallengeHandler.cls
// Payload: { challengeId }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_RemoveChallengeHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String challengeId = (String) data.get('challengeId');

        if (challengeId == null) {
            return new Map<String, Object>{ 'error' => 'Missing challengeId' };
        }

        List<Challenge__c> challenges = [SELECT Id FROM Challenge__c WHERE Id = :challengeId LIMIT 1];
        if (challenges.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Challenge not found' };
        }

        delete challenges[0];
        return new Map<String, Object>{ 'success' => true };
    }
}

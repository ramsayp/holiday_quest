// ─────────────────────────────────────────────────────────────────
// HQ_ReopenHolidayHandler.cls
// Payload: { holidayId }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_ReopenHolidayHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String holidayId = (String) data.get('holidayId');

        if (holidayId == null) {
            return new Map<String, Object>{ 'error' => 'Missing holidayId' };
        }

        List<Holiday__c> holidays = [
            SELECT Id, Wrapped__c
            FROM Holiday__c
            WHERE Id = :holidayId
            LIMIT 1
        ];

        if (holidays.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Holiday not found' };
        }

        holidays[0].Wrapped__c = false;
        update holidays[0];

        return new Map<String, Object>{ 'success' => true };
    }
}
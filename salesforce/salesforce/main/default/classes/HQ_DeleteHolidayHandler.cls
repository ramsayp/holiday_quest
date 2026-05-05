global without sharing class HQ_DeleteHolidayHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String holidayId = (String) data.get('holidayId');

        if (holidayId == null) {
            return new Map<String, Object>{ 'error' => 'Missing holidayId' };
        }

        List<Holiday__c> holidays = [SELECT Id FROM Holiday__c WHERE Id = :holidayId LIMIT 1];
        if (holidays.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Holiday not found' };
        }

        try {
            delete holidays[0];
        } catch (DmlException e) {
            return new Map<String, Object>{ 'error' => 'Could not delete: ' + e.getMessage() };
        }

        return new Map<String, Object>{ 'success' => true };
    }
}

// ─────────────────────────────────────────────────────────────────
// HQ_GetHolidayStateHandler.cls — updated to require holidayId
// Payload: { holidayId }
// ─────────────────────────────────────────────────────────────────
global without sharing class HQ_GetHolidayStateHandler implements RestAPIPostInterface {
    global Map<String, Object> process(Object payload) {
        Map<String, Object> data = (Map<String, Object>) payload;
        String holidayId = (String) data.get('holidayId');
 
        if (holidayId == null) {
            return new Map<String, Object>{ 'error' => 'Missing holidayId' };
        }
 
        List<Holiday__c> holidays = [
            SELECT Id, Name, Wrapped__c
            FROM Holiday__c
            WHERE Id = :holidayId
            LIMIT 1
        ];
 
        if (holidays.isEmpty()) {
            return new Map<String, Object>{ 'error' => 'Holiday not found' };
        }
 
        Holiday__c holiday = holidays[0];
 
        // Players
        List<Map<String, Object>> playerList = new List<Map<String, Object>>();
        for (Player__c p : [
            SELECT Id, Name, Color__c, Is_Admin__c, Client__c
            FROM Player__c
            WHERE Holiday__c = :holidayId
            ORDER BY CreatedDate ASC
        ]) {
            playerList.add(new Map<String, Object>{
                'id'       => p.Id,
                'name'     => p.Name,
                'color'    => p.Color__c,
                'isAdmin'  => p.Is_Admin__c,
                'clientId' => p.Client__c
            });
        }
 
        // Places
        List<Map<String, Object>> placeList = new List<Map<String, Object>>();
        for (Place__c pl : [
            SELECT Id, Name, Category__c, Points__c
            FROM Place__c
            WHERE Holiday__c = :holidayId
            ORDER BY CreatedDate ASC
        ]) {
            placeList.add(new Map<String, Object>{
                'id'       => pl.Id,
                'name'     => pl.Name,
                'category' => pl.Category__c,
                'points'   => pl.Points__c
            });
        }
 
        // Checkins
        List<Map<String, Object>> checkinList = new List<Map<String, Object>>();
        for (Checkin__c c : [
            SELECT Id, Player__c, Place__c, Tagged_By__c, Parent_Checkin__c, CreatedDate
            FROM Checkin__c
            WHERE Player__r.Holiday__c = :holidayId
            ORDER BY CreatedDate ASC
        ]) {
            checkinList.add(new Map<String, Object>{
                'id'              => c.Id,
                'playerId'        => c.Player__c,
                'placeId'         => c.Place__c,
                'taggedById'      => c.Tagged_By__c,
                'parentCheckinId' => c.Parent_Checkin__c,
                'isTag'           => c.Tagged_By__c != null,
                'timestamp'       => c.CreatedDate.getTime()
            });
        }
 
        // Challenges
        List<Map<String, Object>> challengeList = new List<Map<String, Object>>();
        for (Challenge__c ch : [
            SELECT Id, Name, Notes__c, Place__c, Created_By__c
            FROM Challenge__c
            WHERE Holiday__c = :holidayId
            ORDER BY CreatedDate ASC
        ]) {
            challengeList.add(new Map<String, Object>{
                'id'          => ch.Id,
                'name'        => ch.Name,
                'notes'       => ch.Notes__c,
                'placeId'     => ch.Place__c,
                'createdById' => ch.Created_By__c
            });
        }

        return new Map<String, Object>{
            'holidayId'  => holiday.Id,
            'name'       => holiday.Name,
            'wrapped'    => holiday.Wrapped__c,
            'players'    => playerList,
            'places'     => placeList,
            'checkins'   => checkinList,
            'challenges' => challengeList
        };
    }
}
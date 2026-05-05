// ─────────────────────────────────────────────────────────────────
// RestAPIPostFactory.cls — full updated version
// ─────────────────────────────────────────────────────────────────
global class RestAPIPostFactory {
    public static RestAPIPostInterface getHandler(String type) {
        switch on type {
            // Platform level
            when 'CreateClient'      { return new CreateClientHandler(); }
            when 'VerifyClient'      { return new VerifyClientHandler(); }
            when 'SetupAccount'      { return new SetupAccountHandler(); }
            when 'CheckEmail'        { return new CheckEmailHandler(); }
            // HolidayQuest app
            when 'CreateHoliday'     { return new HQ_CreateHolidayHandler(); }
            when 'GetMyHolidays'     { return new HQ_GetMyHolidaysHandler(); }
            when 'GetHolidayState'   { return new HQ_GetHolidayStateHandler(); }
            when 'AddPlayerByEmail'  { return new HQ_AddPlayerByEmailHandler(); }
            when 'CreateCheckin'     { return new HQ_CreateCheckinHandler(); }
            when 'UpdatePlayer'      { return new HQ_UpdatePlayerHandler(); }
            when 'RemovePlayer'      { return new HQ_RemovePlayerHandler(); }
            when 'AddPlace'          { return new HQ_AddPlaceHandler(); }
            when 'RemovePlace'       { return new HQ_RemovePlaceHandler(); }
            when 'UpdatePlace'       { return new HQ_UpdatePlaceHandler(); }
            when 'AddChallenge'             { return new HQ_AddChallengeHandler(); }
            when 'RemoveChallenge'          { return new HQ_RemoveChallengeHandler(); }
            when 'CreateChallengeCheckin'   { return new HQ_CreateChallengeCheckinHandler(); }
            when 'WrapHoliday'       { return new HQ_WrapHolidayHandler(); }
            when 'ReopenHoliday'     { return new HQ_ReopenHolidayHandler(); }
            when 'DeleteHoliday'     { return new HQ_DeleteHolidayHandler(); }
            when else                { return null; }
        }
    }
}
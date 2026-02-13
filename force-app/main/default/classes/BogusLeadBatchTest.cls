/**
 * @description Test class for BogusLeadBatch.
 *              Validates that unconverted Leads created over a month ago
 *              get their Status updated to "Bogus", and other Leads are unaffected.
 */
@IsTest
private class BogusLeadBatchTest {

    private static final String STATUS_BOGUS = 'Bogus';
    private static final String STATUS_OPEN = 'Open - Not Contacted';

    @TestSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>();

        // Leads that should be marked as Bogus (old, unconverted)
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                FirstName = 'Old',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = STATUS_OPEN
            ));
        }

        // Recent leads that should NOT be marked as Bogus
        for (Integer i = 0; i < 3; i++) {
            leads.add(new Lead(
                FirstName = 'Recent',
                LastName = 'Lead ' + i,
                Company = 'Recent Company ' + i,
                Status = STATUS_OPEN
            ));
        }

        // Lead already marked as Bogus — should be skipped by the query
        leads.add(new Lead(
            FirstName = 'Already',
            LastName = 'Bogus Lead',
            Company = 'Bogus Company',
            Status = STATUS_BOGUS
        ));

        insert leads;
    }

    @IsTest
    static void testBogusLeadBatch() {
        // Backdate old leads to more than one month ago
        List<Lead> oldLeads = [
            SELECT Id FROM Lead WHERE FirstName = 'Old'
        ];
        Test.setCreatedDate(oldLeads[0].Id, DateTime.now().addMonths(-2));
        Test.setCreatedDate(oldLeads[1].Id, DateTime.now().addMonths(-2));
        Test.setCreatedDate(oldLeads[2].Id, DateTime.now().addMonths(-2));
        Test.setCreatedDate(oldLeads[3].Id, DateTime.now().addMonths(-2));
        Test.setCreatedDate(oldLeads[4].Id, DateTime.now().addMonths(-2));

        Test.startTest();
        Database.executeBatch(new BogusLeadBatch(), 200);
        Test.stopTest();

        // Verify old leads are now Bogus
        List<Lead> markedBogus = [
            SELECT Id, FirstName, Status
            FROM Lead
            WHERE FirstName = 'Old'
        ];

        for (Lead lead : markedBogus) {
            System.assertEquals(STATUS_BOGUS, lead.Status,
                'Old Lead "' + lead.LastName + '" should have Status = Bogus');
        }

        // Verify recent leads remain unchanged
        List<Lead> recentLeads = [
            SELECT Id, FirstName, Status
            FROM Lead
            WHERE FirstName = 'Recent'
        ];

        for (Lead lead : recentLeads) {
            System.assertEquals(STATUS_OPEN, lead.Status,
                'Recent Lead "' + lead.LastName + '" should remain ' + STATUS_OPEN);
        }
    }

    @IsTest
    static void testBogusLeadBatchNoRecords() {
        // Delete all leads so the batch processes nothing
        delete [SELECT Id FROM Lead];

        Test.startTest();
        Database.executeBatch(new BogusLeadBatch(), 200);
        Test.stopTest();

        List<Lead> remainingLeads = [SELECT Id FROM Lead];
        System.assertEquals(0, remainingLeads.size(),
            'No Lead records should exist');
    }

    @IsTest
    static void testBogusLeadBatchSkipsAlreadyBogus() {
        // Backdate the already-bogus lead
        Lead bogusLead = [SELECT Id FROM Lead WHERE FirstName = 'Already' LIMIT 1];
        Test.setCreatedDate(bogusLead.Id, DateTime.now().addMonths(-2));

        Test.startTest();
        Database.executeBatch(new BogusLeadBatch(), 200);
        Test.stopTest();

        // The already-bogus lead should still be Bogus (was skipped by the query, not reprocessed)
        Lead result = [SELECT Id, Status FROM Lead WHERE FirstName = 'Already' LIMIT 1];
        System.assertEquals(STATUS_BOGUS, result.Status,
            'Already Bogus lead should remain Bogus');
    }
}

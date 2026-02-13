/**
 * @description Test class for BeerArchiveBatch.
 *              Validates that Beer records with Tags = "Archive" get their
 *              Status updated to "Archive", and other records are unaffected.
 */
@IsTest
private class BeerArchiveBatchTest {

    @TestSetup
    static void setupTestData() {
        List<Beer__c> beers = new List<Beer__c>();

        // Records that should be archived
        for (Integer i = 0; i < 5; i++) {
            beers.add(new Beer__c(
                Name = 'Archive Beer ' + i,
                coder_Tags__c = 'Archive',
                Status__c = 'Available'
            ));
        }

        // Records that should NOT be archived
        for (Integer i = 0; i < 3; i++) {
            beers.add(new Beer__c(
                Name = 'Active Beer ' + i,
                coder_Tags__c = 'IPA',
                Status__c = 'Available'
            ));
        }

        // Record already archived — should be skipped by the query
        beers.add(new Beer__c(
            Name = 'Already Archived Beer',
            coder_Tags__c = 'Archive',
            Status__c = 'Archive'
        ));

        insert beers;
    }

    @IsTest
    static void testBeerArchiveBatch() {
        Test.startTest();
        Database.executeBatch(new BeerArchiveBatch(), 200);
        Test.stopTest();

        List<Beer__c> archivedBeers = [
            SELECT Id, Name, Status__c
            FROM Beer__c
            WHERE coder_Tags__c = 'Archive'
        ];

        for (Beer__c beer : archivedBeers) {
            System.assertEquals('Archive', beer.Status__c,
                'Beer "' + beer.Name + '" should have Status = Archive');
        }

        List<Beer__c> activeBeers = [
            SELECT Id, Name, Status__c
            FROM Beer__c
            WHERE coder_Tags__c != 'Archive'
        ];

        for (Beer__c beer : activeBeers) {
            System.assertEquals('Available', beer.Status__c,
                'Beer "' + beer.Name + '" should remain Available');
        }
    }

    @IsTest
    static void testBeerArchiveBatchNoRecords() {
        // Delete all archive-tagged records so the batch processes nothing
        delete [SELECT Id FROM Beer__c WHERE coder_Tags__c = 'Archive'];

        Test.startTest();
        Database.executeBatch(new BeerArchiveBatch(), 200);
        Test.stopTest();

        List<Beer__c> remainingBeers = [
            SELECT Id, Status__c
            FROM Beer__c
        ];

        for (Beer__c beer : remainingBeers) {
            System.assertEquals('Available', beer.Status__c,
                'No records should have been archived');
        }
    }
}

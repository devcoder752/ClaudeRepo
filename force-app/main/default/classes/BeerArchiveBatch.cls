/**
 * @description Batch class to archive Beer records where the Tags field
 *              contains "Archive". Sets the Status picklist to "Archive"
 *              for matching records.
 *
 * @usage
 *   Database.executeBatch(new BeerArchiveBatch(), 200);
 */
public with sharing class BeerArchiveBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String TAG_ARCHIVE = 'Archive';

    /**
     * @description Status picklist values for Beer__c.Status__c.
     */
    public enum BeerStatus {
        AVAILABLE,
        ARCHIVE
    }

    private Integer totalProcessed = 0;
    private Integer totalFailed = 0;

    /**
     * @description Queries Beer records where Tags equals "Archive"
     *              and Status is not already set to "Archive".
     * @param bc The batch context.
     * @return A QueryLocator for the matching Beer records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, coder_Tags__c, Status__c ' +
            'FROM Beer__c ' +
            'WHERE coder_Tags__c = :TAG_ARCHIVE ' +
            'AND Status__c != :TAG_ARCHIVE'
        );
    }

    /**
     * @description Updates each Beer record's Status to "Archive".
     * @param bc The batch context.
     * @param scope The list of Beer records to process.
     */
    public void execute(Database.BatchableContext bc, List<Beer__c> scope) {
        for (Beer__c beer : scope) {
            beer.Status__c = TAG_ARCHIVE;
        }

        List<Database.SaveResult> results = Database.update(scope, false, AccessLevel.USER_MODE);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                totalProcessed++;
            } else {
                totalFailed++;
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'BeerArchiveBatch - Failed to archive Beer Id: ' + sr.getId() +
                        ' | Error: ' + err.getMessage()
                    );
                }
            }
        }
    }

    /**
     * @description Logs a summary of the batch execution results.
     * @param bc The batch context.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'BeerArchiveBatch Complete - Archived: ' + totalProcessed +
            ' | Failed: ' + totalFailed
        );
    }
}

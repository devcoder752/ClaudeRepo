/**
 * @description Batch class to mark unconverted Lead records as "Bogus" when
 *              they were created more than one month ago. Only processes Leads
 *              that are not already converted and whose Status is not already "Bogus".
 *
 * @usage
 *   Database.executeBatch(new BogusLeadBatch(), 200);
 */
public with sharing class BogusLeadBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String STATUS_BOGUS = 'Bogus';

    /**
     * @description Lead status picklist values relevant to this batch.
     */
    public enum LeadStatus {
        BOGUS
    }

    @TestVisible
    private Integer totalProcessed = 0;
    @TestVisible
    private Integer totalFailed = 0;

    /**
     * @description Queries unconverted Leads created more than one month ago
     *              whose Status is not already "Bogus".
     * @param bc The batch context.
     * @return A QueryLocator for the matching Lead records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime oneMonthAgo = DateTime.now().addMonths(-1);
        return Database.getQueryLocator(
            'SELECT Id, Status ' +
            'FROM Lead ' +
            'WHERE IsConverted = false ' +
            'AND CreatedDate < :oneMonthAgo ' +
            'AND Status != :STATUS_BOGUS'
        );
    }

    /**
     * @description Updates each Lead record's Status to "Bogus".
     * @param bc The batch context.
     * @param scope The list of Lead records to process.
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        for (Lead lead : scope) {
            lead.Status = STATUS_BOGUS;
        }

        List<Database.SaveResult> results = Database.update(scope, false, AccessLevel.USER_MODE);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                totalProcessed++;
            } else {
                totalFailed++;
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'BogusLeadBatch - Failed to update Lead Id: ' + sr.getId() +
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
            'BogusLeadBatch Complete - Marked Bogus: ' + totalProcessed +
            ' | Failed: ' + totalFailed
        );
    }
}

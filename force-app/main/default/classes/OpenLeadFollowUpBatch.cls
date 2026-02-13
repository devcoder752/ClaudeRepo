/**
 * @description Batch class to create follow-up Tasks for open Lead records
 *              that have been open for more than 60 days. Each Task is assigned
 *              to the Lead owner with a 2-day due date.
 *
 * @usage
 *   Database.executeBatch(new OpenLeadFollowUpBatch(), 200);
 */
public with sharing class OpenLeadFollowUpBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String LEAD_STATUS_OPEN = 'Open - Not Contacted';
    private static final String TASK_SUBJECT = 'Close the Lead or mark it Bogus';
    private static final Integer DAYS_THRESHOLD = 60;
    private static final Integer DUE_DATE_OFFSET = 2;

    /**
     * @description Task status picklist values relevant to this batch.
     */
    public enum TaskStatus {
        NOT_STARTED,
        COMPLETED
    }

    @TestVisible
    private Integer totalProcessed = 0;
    @TestVisible
    private Integer totalFailed = 0;

    /**
     * @description Queries open, unconverted Leads created more than 60 days ago.
     * @param bc The batch context.
     * @return A QueryLocator for the matching Lead records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime sixtyDaysAgo = DateTime.now().addDays(-DAYS_THRESHOLD);
        return Database.getQueryLocator(
            'SELECT Id, OwnerId ' +
            'FROM Lead ' +
            'WHERE IsConverted = false ' +
            'AND Status = :LEAD_STATUS_OPEN ' +
            'AND CreatedDate < :sixtyDaysAgo'
        );
    }

    /**
     * @description Creates a follow-up Task for each Lead in scope.
     * @param bc The batch context.
     * @param scope The list of Lead records to process.
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Task> tasksToInsert = new List<Task>();

        for (Lead lead : scope) {
            tasksToInsert.add(new Task(
                Subject = TASK_SUBJECT,
                WhoId = lead.Id,
                OwnerId = lead.OwnerId,
                ActivityDate = Date.today().addDays(DUE_DATE_OFFSET),
                Priority = 'Normal',
                Status = 'Not Started'
            ));
        }

        List<Database.SaveResult> results = Database.insert(tasksToInsert, false, AccessLevel.USER_MODE);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                totalProcessed++;
            } else {
                totalFailed++;
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'OpenLeadFollowUpBatch - Failed to create Task for Lead: ' +
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
            'OpenLeadFollowUpBatch Complete - Tasks Created: ' + totalProcessed +
            ' | Failed: ' + totalFailed
        );
    }
}

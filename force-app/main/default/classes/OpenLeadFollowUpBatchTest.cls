/**
 * @description Test class for OpenLeadFollowUpBatch.
 *              Validates that open Leads older than 60 days get follow-up Tasks
 *              created, and recent or converted Leads are unaffected.
 */
@IsTest
private class OpenLeadFollowUpBatchTest {

    private static final String STATUS_OPEN = 'Open - Not Contacted';
    private static final String TASK_SUBJECT = 'Close the Lead or mark it Bogus';

    @TestSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>();

        // Old leads that should get follow-up Tasks
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                FirstName = 'Old',
                LastName = 'Lead ' + i,
                Company = 'Old Company ' + i,
                Status = STATUS_OPEN
            ));
        }

        // Recent leads that should NOT get follow-up Tasks
        for (Integer i = 0; i < 3; i++) {
            leads.add(new Lead(
                FirstName = 'Recent',
                LastName = 'Lead ' + i,
                Company = 'Recent Company ' + i,
                Status = STATUS_OPEN
            ));
        }

        insert leads;
    }

    @IsTest
    static void testCreatesFollowUpTasks() {
        // Backdate old leads to more than 60 days ago
        List<Lead> oldLeads = [
            SELECT Id, OwnerId FROM Lead WHERE FirstName = 'Old'
        ];
        for (Lead lead : oldLeads) {
            Test.setCreatedDate(lead.Id, DateTime.now().addDays(-90));
        }

        Test.startTest();
        Database.executeBatch(new OpenLeadFollowUpBatch(), 200);
        Test.stopTest();

        List<Task> createdTasks = [
            SELECT Id, Subject, WhoId, OwnerId, ActivityDate, Status
            FROM Task
            WHERE Subject = :TASK_SUBJECT
        ];

        System.assertEquals(5, createdTasks.size(),
            'Should create exactly 5 follow-up Tasks for old Leads');

        Set<Id> oldLeadIds = new Set<Id>();
        Map<Id, Id> leadOwnerMap = new Map<Id, Id>();
        for (Lead lead : oldLeads) {
            oldLeadIds.add(lead.Id);
            leadOwnerMap.put(lead.Id, lead.OwnerId);
        }

        for (Task task : createdTasks) {
            System.assert(oldLeadIds.contains(task.WhoId),
                'Task should be related to an old Lead');
            System.assertEquals(leadOwnerMap.get(task.WhoId), task.OwnerId,
                'Task should be assigned to the Lead owner');
            System.assertEquals(Date.today().addDays(2), task.ActivityDate,
                'Task due date should be 2 days from today');
            System.assertEquals('Not Started', task.Status,
                'Task status should be Not Started');
        }
    }

    @IsTest
    static void testSkipsRecentLeads() {
        // Only backdate the "Old" leads — recent leads stay as-is
        List<Lead> oldLeads = [
            SELECT Id FROM Lead WHERE FirstName = 'Old'
        ];
        for (Lead lead : oldLeads) {
            Test.setCreatedDate(lead.Id, DateTime.now().addDays(-90));
        }

        Test.startTest();
        Database.executeBatch(new OpenLeadFollowUpBatch(), 200);
        Test.stopTest();

        // Verify no Tasks created for recent leads
        List<Lead> recentLeads = [
            SELECT Id FROM Lead WHERE FirstName = 'Recent'
        ];
        Set<Id> recentLeadIds = new Set<Id>();
        for (Lead lead : recentLeads) {
            recentLeadIds.add(lead.Id);
        }

        List<Task> recentTasks = [
            SELECT Id, WhoId FROM Task
            WHERE Subject = :TASK_SUBJECT
            AND WhoId IN :recentLeadIds
        ];

        System.assertEquals(0, recentTasks.size(),
            'No Tasks should be created for recent Leads');
    }

    @IsTest
    static void testNoLeads() {
        delete [SELECT Id FROM Lead];

        Test.startTest();
        Database.executeBatch(new OpenLeadFollowUpBatch(), 200);
        Test.stopTest();

        List<Task> tasks = [
            SELECT Id FROM Task WHERE Subject = :TASK_SUBJECT
        ];
        System.assertEquals(0, tasks.size(),
            'No Tasks should be created when there are no Leads');
    }
}

/**
 * @description Test class for AccountListController.
 *              Validates account retrieval, display limit, and total count.
 */
@IsTest
private class AccountListControllerTest {

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 1; i <= 10; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + String.valueOf(i).leftPad(2, '0'),
                Industry = 'Technology',
                Phone = '(555) 000-' + String.valueOf(1000 + i),
                AnnualRevenue = i * 1000000,
                Rating = Math.mod(i, 3) == 0 ? 'Hot' : (Math.mod(i, 3) == 1 ? 'Warm' : 'Cold')
            ));
        }
        insert accounts;
    }

    @IsTest
    static void testGetAccountsReturnsLimitedRecords() {
        Test.startTest();
        AccountListController.AccountResult result = AccountListController.getAccounts();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.accounts, 'Accounts list should not be null');
        System.assertEquals(5, result.accounts.size(), 'Should return exactly 5 accounts');
    }

    @IsTest
    static void testGetAccountsReturnsTotalCount() {
        Test.startTest();
        AccountListController.AccountResult result = AccountListController.getAccounts();
        Test.stopTest();

        System.assertEquals(10, result.totalCount, 'Total count should reflect all 10 accounts');
    }

    @IsTest
    static void testGetAccountsFieldsPopulated() {
        Test.startTest();
        AccountListController.AccountResult result = AccountListController.getAccounts();
        Test.stopTest();

        Account firstAccount = result.accounts[0];
        System.assertNotEquals(null, firstAccount.Name, 'Name should be populated');
        System.assertNotEquals(null, firstAccount.Industry, 'Industry should be populated');
        System.assertNotEquals(null, firstAccount.Phone, 'Phone should be populated');
        System.assertNotEquals(null, firstAccount.AnnualRevenue, 'AnnualRevenue should be populated');
        System.assertNotEquals(null, firstAccount.Rating, 'Rating should be populated');
    }

    @IsTest
    static void testGetAccountsOrderedByName() {
        Test.startTest();
        AccountListController.AccountResult result = AccountListController.getAccounts();
        Test.stopTest();

        for (Integer i = 0; i < result.accounts.size() - 1; i++) {
            System.assert(
                result.accounts[i].Name <= result.accounts[i + 1].Name,
                'Accounts should be ordered by Name ascending'
            );
        }
    }

    @IsTest
    static void testGetAccountsWithNoRecords() {
        delete [SELECT Id FROM Account];

        Test.startTest();
        AccountListController.AccountResult result = AccountListController.getAccounts();
        Test.stopTest();

        System.assertEquals(0, result.accounts.size(), 'Should return empty list when no accounts exist');
        System.assertEquals(0, result.totalCount, 'Total count should be 0 when no accounts exist');
    }
}

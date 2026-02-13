/**
 * @description Controller for the myAccounts LWC component.
 *              Retrieves a limited set of Account records and the total count
 *              for display in a card-based UI.
 * Deploying through MCP
 */
public with sharing class AccountListController {

    private static final Integer DISPLAY_LIMIT = 5;

    /**
     * @description Wrapper class to return both the account list and total count.
     */
    public class AccountResult {
        @AuraEnabled public List<Account> accounts;
        @AuraEnabled public Integer totalCount;
    }

    /**
     * @description Retrieves up to 5 Account records and the total Account count.
     * @return AccountResult containing the accounts and total count.
     */
    @AuraEnabled(cacheable=true)
    public static AccountResult getAccounts() {
        AccountResult result = new AccountResult();

        result.accounts = [
            SELECT Name, Industry, Phone, AnnualRevenue, Rating
            FROM Account
            WITH USER_MODE
            ORDER BY Name ASC
            LIMIT :DISPLAY_LIMIT
        ];

        result.totalCount = [
            SELECT COUNT()
            FROM Account
            WITH USER_MODE
        ];

        return result;
    }
}

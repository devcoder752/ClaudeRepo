/**
 * @description Handler class for AccountTrigger. Contains all business logic
 *              for Account trigger events. Uses a static flag to prevent recursion.
 */
public with sharing class AccountTriggerHandler {

    /** @description Recursion guard — set to true to skip re-entrant trigger execution. */
    public static Boolean hasRun = false;

    /**
     * @description Handles before insert logic for Account records.
     * @param newAccounts List of Account records being inserted.
     */
    public static void beforeInsert(List<Account> newAccounts) {
        // TODO: Add before insert business logic
    }

    /**
     * @description Handles before update logic for Account records.
     * @param newAccounts List of Account records with updated values.
     * @param oldAccountMap Map of Account records with previous values, keyed by Id.
     */
    public static void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        // TODO: Add before update business logic
    }

    /**
     * @description Handles after insert logic for Account records.
     * @param newAccounts List of Account records that were inserted.
     */
    public static void afterInsert(List<Account> newAccounts) {
        // TODO: Add after insert business logic
    }

    /**
     * @description Handles after update logic for Account records.
     * @param newAccounts List of Account records with updated values.
     * @param oldAccountMap Map of Account records with previous values, keyed by Id.
     */
    public static void afterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        // TODO: Add after update business logic
    }
}

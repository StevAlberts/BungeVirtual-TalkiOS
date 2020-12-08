/**
 * @copyright Copyright (c) 2020 Ivan Sein <ivan@nextcloud.com>
 *
 * @author Ivan Sein <ivan@nextcloud.com>
 *
 * @license GNU GPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "NCContactsManager.h"

#import <Contacts/Contacts.h>

#import "NCAPIController.h"
#import "NCDatabaseManager.h"
#import "ABContact.h"
#import "NCContact.h"

@interface NCContactsManager ()

@property (nonatomic, strong) CNContactStore *contactStore;

@end

@implementation NCContactsManager

+ (NCContactsManager *)sharedInstance
{
    static dispatch_once_t once;
    static NCContactsManager *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _contactStore = [[CNContactStore alloc] init];
    }
    return self;
}

- (void)requestContactsAccess
{
    [_contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            [self searchInServerForAddressBookContacts];
        }
    }];
}

- (BOOL)isContactAccessDetermined
{
    return [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] != CNAuthorizationStatusNotDetermined;
}

- (BOOL)isContactAccessAuthorized
{
    return [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized;
}

- (void)searchInServerForAddressBookContacts
{
    if ([self isContactAccessAuthorized]) {
        NSMutableDictionary *phoneNumbersDict = [NSMutableDictionary new];
        NSMutableArray *contacts = [NSMutableArray new];
        NSInteger updateTimestamp = [[NSDate date] timeIntervalSince1970];
        NSError *error = nil;
        NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        [_contactStore enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
            NSMutableArray *phoneNumbers = [NSMutableArray new];
            for (CNLabeledValue *phoneNumberValue in contact.phoneNumbers) {
                [phoneNumbers addObject:[[phoneNumberValue valueForKey:@"value"] valueForKey:@"digits"]];
            }
            if (phoneNumbers.count > 0) {
                NSString *identifier = [contact valueForKey:@"identifier"];
                NSString *givenName = [contact valueForKey:@"givenName"];
                NSString *familyName = [contact valueForKey:@"familyName"];
                NSString *name = [[NSString stringWithFormat:@"%@ %@", givenName, familyName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                ABContact *abContact = [ABContact contactWithIdentifier:identifier name:name phoneNumbers:phoneNumbers lastUpdate:updateTimestamp];
                if (abContact) {
                    [contacts addObject:abContact];
                }
                [phoneNumbersDict setValue:phoneNumbers forKey:identifier];
            }
        }];
        [self updateAddressBookCopyWithContacts:contacts andTimestamp:updateTimestamp];
        [self searchForPhoneNumbers:phoneNumbersDict forAccount:[[NCDatabaseManager sharedInstance] activeAccount]];
    } else if (![self isContactAccessDetermined]) {
        [self requestContactsAccess];
    }
}

- (void)updateAddressBookCopyWithContacts:(NSArray *)contacts andTimestamp:(NSInteger)timestamp
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        // Add or update contacts
        for (ABContact *contact in contacts) {
            ABContact *managedABContact = [ABContact objectsWhere:@"identifier = %@", contact.identifier].firstObject;
            if (managedABContact) {
                [ABContact updateContact:managedABContact withContact:contact];
            } else {
                [realm addObject:contact];
            }
        }
        // Delete old contacts
        NSPredicate *query = [NSPredicate predicateWithFormat:@"lastUpdate != %ld", (long)timestamp];
        RLMResults *managedABContactsToBeDeleted = [ABContact objectsWithPredicate:query];
        // Delete matching nc contacts
        for (ABContact *managedABContact in managedABContactsToBeDeleted) {
            NSPredicate *query2 = [NSPredicate predicateWithFormat:@"identifier = %@", managedABContact.identifier];
            [realm deleteObjects:[NCContact objectsWithPredicate:query2]];
        }
        [realm deleteObjects:managedABContactsToBeDeleted];
        NSLog(@"Address Book Contacts updated");
    }];
}

- (void)searchForPhoneNumbers:(NSDictionary *)phoneNumbers forAccount:(TalkAccount *)account
{
    [[NCAPIController sharedInstance] searchContactsForAccount:account withPhoneNumbers:phoneNumbers andCompletionBlock:^(NSDictionary *contacts, NSError *error) {
        if (!error && contacts.count > 0) {
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm transactionWithBlock:^{
                // Add or update matched contacts
                NSInteger updateTimestamp = [[NSDate date] timeIntervalSince1970];
                for (NSString *identifier in contacts.allKeys) {
                    NSString *cloudId = [contacts objectForKey:identifier];
                    NCContact *contact = [NCContact contactWithIdentifier:identifier cloudId:cloudId lastUpdate:updateTimestamp andAccountId:account.accountId];
                    NCContact *managedNCContact = [NCContact objectsWhere:@"identifier = %@ AND accountId = %@", identifier, account.accountId].firstObject;
                    if (managedNCContact) {
                        [NCContact updateContact:managedNCContact withContact:contact];
                    } else {
                        [realm addObject:contact];
                    }
                }
                // Delete old contacts
                NSPredicate *query = [NSPredicate predicateWithFormat:@"lastUpdate != %ld", (long)updateTimestamp];
                RLMResults *managedNCContactsToBeDeleted = [NCContact objectsWithPredicate:query];
                [realm deleteObjects:managedNCContactsToBeDeleted];
                NSLog(@"Matched NC Contacts updated");
            }];
        }
    }];
}

@end

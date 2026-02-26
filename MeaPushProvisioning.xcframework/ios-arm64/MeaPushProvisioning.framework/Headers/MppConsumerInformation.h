//
// MppConsumerInformation.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import "MppPhone.h"

/**
 * Consumer information used for Click To Pay push provisioning.
 */
@interface MppConsumerInformation : NSObject
/**
 * @name MppConsumerInformation properties
 */

/**
 * External consumer id.
 */
@property (nonatomic, copy, readonly, nullable) NSString *externalConsumerId;

/**
 * First name.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *firstName;

/**
 * Middle name.
 */
@property (nonatomic, copy, readonly, nullable) NSString *middleName;

/**
 * Last name.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *lastName;

/**
 * Phones.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<MppPhone *> *phones;

/**
 * Emails.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<NSString *> *emails;

/**
 * Locale.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *locale;

/**
 * Country Code
 */
@property (nonatomic, copy, readonly, nonnull) NSString *countryCode;


/**
 * @name MppConsumerInformation methods
 */

/**
 * Creates consumer information object.
 *
 * @param externalConsumerId    External consumer id.
 * @param firstName             First name.
 * @param middleName            Middle name.
 * @param lastName              Last name.
 * @param phone                 Phone.
 * @param email                 Email.
 * @param locale                Locale.
 * @param countryCode           Country code.
 */
+ (instancetype _Nullable)consumerInformationWithExternalConsumerId:(NSString *_Nullable)externalConsumerId
                                                firstName:(NSString *_Nonnull)firstName
                                               middleName:(NSString *_Nullable)middleName
                                                 lastname:(NSString *_Nonnull)lastName
                                                    phone:(MppPhone *_Nonnull)phone
                                                    email:(NSString *_Nonnull)email
                                                   locale:(NSString *_Nonnull)locale
                                              countryCode:(NSString *_Nonnull)countryCode;
/**
 * Creates consumer information object from dictionary.
 *
 * @param dictionary Dictionary.
 */
+ (instancetype _Nullable)consumerInformationWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Dictionary representing consumer information.
 *
 * @return Dictionary representing consumer information.
 */
- (NSDictionary *_Nonnull)toDictionary;

/**
 * Verify if consumer information is valid.
 *
 * @return `true` value if consumer information is valid.
 */
- (BOOL)isValid;

@end

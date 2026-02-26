//
// MppCard.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MppBillingAddress;

/**
 * Card object used for Click To Pay push provisioning.
 */
@interface MppCard : NSObject
/**
 * @name MppCard properties
 */

/**
 * Last four digits of payment card number.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *lastFourDigits;

/**
 * Cardholder name.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *cardholderName;

/**
 * Expiry year.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *expiryYear;

/**
 * Expiry month.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *expiryMonth;

/**
 * Billing address.
 */
@property (nonatomic, copy, readonly, nonnull) MppBillingAddress *billingAddress;

/**
 * External card id.
 */
@property (nonatomic, copy, readonly, nullable) NSString *externalCardId;

/**
 * @name MppCard methods
 */

/**
 * Creates card object with dictionary.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nonnull)dict;

@end

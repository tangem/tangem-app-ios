//
// MppPhone.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//
        
/**
 * Phone object used for Click To Pay push provisioning.
 */
#import <Foundation/Foundation.h>

@interface MppPhone : NSObject
/**
 * @name MppPhone properties
 */

/**
 * Country code.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *countryCode;

/**
 * Phone number
 */
@property (nonatomic, copy, readonly, nonnull) NSString *phoneNumber;


/**
 * @name MppPhone methods
 */

/**
 * Creates phone object.
 *
 * @param countryCode   Country code
 * @param phoneNumber   Phone number
 */
+ (instancetype _Nullable)phoneWithCountryCode:(NSString *_Nonnull)countryCode phoneNumber:(NSString *_Nonnull)phoneNumber;

/**
 * Creates phone object from dictionary.
 */
- (NSDictionary *_Nonnull)toDictionary;

@end

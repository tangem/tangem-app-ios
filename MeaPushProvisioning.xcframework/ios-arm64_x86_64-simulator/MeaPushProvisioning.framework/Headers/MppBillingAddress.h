//
// MppBillingAddress.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Billing address used for Click To Pay push provisioning.
 */
@interface MppBillingAddress : NSObject
/**
 * @name MppBillingAddress properties
 */

/**
 * Address line 1.
 */
@property (nonatomic, copy, readonly, nullable) NSString *addressLine1;

/**
 * Address line 2.
 */
@property (nonatomic, copy, readonly, nullable) NSString *addressLine2;

/**
 * Address line 3.
 */
@property (nonatomic, copy, readonly, nullable) NSString *addressLine3;

/**
 * City.
 */
@property (nonatomic, copy, readonly, nullable) NSString *city;

/**
 * Postal code.
 */
@property (nonatomic, copy, readonly, nullable) NSString *postalCode;

/**
 * Country subdivision.
 */
@property (nonatomic, copy, readonly, nullable) NSString *countrySubdivision;

/**
 * Country.
 */
@property (nonatomic, copy, readonly, nullable) NSString *country;


/**
 * @name MppBillingAddress methods
 */

/**
 * Creates billing address object.
 *
 * @param addressLine1          Address line 1.
 * @param addressLine2          Address line 2.
 * @param addressLine3          Address line 3.
 * @param city                  City.
 * @param postalCode            Postal code.
 * @param countrySubdivision    Country subdivision.
 * @param country               Country.
 */
+ (instancetype _Nullable)billingAddressWithAddressLine1:(NSString *_Nonnull)addressLine1
                                            addressLine2:(NSString *_Nonnull)addressLine2
                                            addressLine3:(NSString *_Nonnull)addressLine3
                                                    city:(NSString *_Nonnull)city
                                              postalCode:(NSString *_Nonnull)postalCode
                                      countrySubdivision:(NSString *_Nonnull)countrySubdivision
                                                 country:(NSString *_Nonnull)country;
/**
 * Creates billing address with dictionary.
 *
 * @param dictionary Dictionary.
 */
+ (instancetype _Nullable)billingAddressWithDictionary:(NSDictionary* _Nonnull)dictionary;

/**
 * Dictionary representing billing address.
 *
 * @return Dictionary representing billing address.
 */
- (NSDictionary *_Nonnull)toDictionary;

/**
 * Verify if billing address is valid.
 *
 * @return `true` if billing address is valid.
 */
- (BOOL)isValid;

@end

//
//  MppCheckResponseData.h
//  MeaPushProvisioning
//
//  Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MeaPushProvisioning/MppAvailablePushMethod.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Check response data used for Click To Pay push provisioning.
 */
@interface MppCheckResponseData : NSObject

/**
 * @name MppCheckResponseData properties
 */

/**
 * Array of of tokens IDs.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<NSString *> *tokens;

/**
 * Returns last four digits of payment card number.
 *
 * @return Last four digits of payment card number.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *lastFourDigits;

/**
 * Returns card payment network.
 *
 * @return Card payment network.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *paymentNetwork;

/**
 * @name MppCheckResponseData methods
 */

/**
 * Create check response data with dictionary.
 *
 * @param dictionary Dictionary containing records to create instance of `MppCheckResponseData`.
 *
 * @return MppCheckResponseData object instance.
 */
+ (instancetype)responseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if check response data is valid.
 *
 * @return Bool value if check response response data is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

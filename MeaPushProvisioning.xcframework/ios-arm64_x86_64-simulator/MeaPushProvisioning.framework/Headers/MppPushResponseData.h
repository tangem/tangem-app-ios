//
// MppPushResponseData.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Push response used for Click To Pay push provisioning.
 */
@interface MppPushResponseData : NSObject
/**
 * @name MppPushResponseData properties
 */

/**
 * Request trace id.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *requestTraceId;

/**
 * External consumer id.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *externalConsumerId;

/**
 * External card id.
 */
@property (nonatomic, copy, readonly, nullable) NSString *externalCardId;

/**
 * @name MppPushResponseData methods
 */

/**
 * Creates push response with dictionary.
 */
+ (instancetype _Nullable)responseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if push response data is valid.
 *
 * @return `true` value if push response data is valid.
 */
- (BOOL)isValid;

@end

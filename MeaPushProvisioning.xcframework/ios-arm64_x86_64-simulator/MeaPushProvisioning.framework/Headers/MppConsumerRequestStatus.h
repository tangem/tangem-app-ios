//
// MppConsumerRequestStatus.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MppConsumerRequestDetail;

/**
 * Consumer request status.
 */
@interface MppConsumerRequestStatus : NSObject
/**
 * @name MppConsumerRequestStatus properties
 */

/**
 * Status code.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *status;

/**
 * External consumer id.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *externalConsumerId;

/**
 * Consumer request details.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<MppConsumerRequestDetail *> *details;


/**
 * @name MppConsumerRequestStatus methods
 */

/**
 * Creatеs consumer request detail with dictionary.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nonnull)dict;

@end

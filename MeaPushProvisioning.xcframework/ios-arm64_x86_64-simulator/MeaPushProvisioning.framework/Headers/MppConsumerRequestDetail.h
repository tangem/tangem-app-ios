//
// MppConsumerRequestDetail.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MppConsumerRequestError;

/**
 * Consumer request detail object used for Click To Pay push provisioning.
 */
@interface MppConsumerRequestDetail : NSObject
/**
 * @name MppConsumerRequestDetail properties
 */

/**
 * Status.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *status;

/**
 * List of errors.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<MppConsumerRequestError *> *errors;


/**
 * @name MppConsumerRequestDetail methods
 */

/**
 * Creates consumer request detail object with dictionary.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nonnull)dict;

@end

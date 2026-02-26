//
// MppConsumerRequestError.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Consumer request error object used for Click To Pay push provisioning.
 */
@interface MppConsumerRequestError : NSObject
/**
 * @name MppConsumerRequestError properties
 */

/**
 * Field name.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *field;

/**
 * Reason of an error.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *reason;


/**
 * @name MppConsumerRequestError methods
 */

/**
 * Creates consumer request error object with dictionary.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nonnull)dict;

@end

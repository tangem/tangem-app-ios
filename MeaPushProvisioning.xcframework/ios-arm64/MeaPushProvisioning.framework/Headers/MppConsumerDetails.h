//
// MppConsumerDetails.h
// MeaPushProvisioning
//
// Copyright © 2024 MeaWallet AS. All rights reserved.
//
        


#import <Foundation/Foundation.h>

@class MppConsumerInformation;
@class MppCard;

/**
 * Consumer details used for Click To Pay push provisioning.
 */
@interface MppConsumerDetails : NSObject
/**
 * @name MppConsumerDetails properties
 */

/**
 * Product name.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *product;

/**
 * Consumer information.
 */
@property (nonatomic, copy, readonly, nonnull) MppConsumerInformation *consumerInformation;
/**
 * List of cards.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<MppCard *> *cards;


/**
 * @name MppConsumerDetails methods
 */

/**
 * Creates consumer details from dictionary.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nonnull)dict;

@end

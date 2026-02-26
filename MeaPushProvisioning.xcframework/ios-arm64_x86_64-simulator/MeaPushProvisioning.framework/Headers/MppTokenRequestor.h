//
//  MeaTokenRequestor.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Token Requestor that is eligible for the account ranges in the request.
 */
@interface MppTokenRequestor : NSObject

/**
 * @name MppTokenRequestor properties
 */

/**
 * Returns identifier of the Token Requestor.
 *
 * @return Identifier of the Token Requestor.
 */
@property (nonatomic, copy, readonly, nullable) NSString *tokenRequestorId;

/**
 * Returns legal name of the token requestor.
 *
 * @return The legal name of the token requestor.
 */
@property (nonatomic, copy, readonly, nullable) NSString *name;

/**
 * Returns the name of the token requestor to be displayed to the account holder.
 *
 * @return The name of the token requestor.
 */
@property (nonatomic, copy, readonly, nullable) NSString *consumerFacingEntityName;

/**
 * Returns image of the token requestor (for instance a logo). Provided as an Asset ID – use the Get Asset API to retrieve the actual asset.
 *
 * @return The Asset ID of image of token requestor.
 */
@property (nonatomic, copy, readonly, nullable) NSString *imageAssetId;

/**
 * Returns the type of the token requestor.
 *
 * @return The type of the token requestor as instance of MppTokenRequestorType object.
 */
@property (nonatomic, copy, readonly, nullable) NSString *tokenRequestorType;

/**
 * Returns the identifier of the Wallet Provider.
 *
 * @return The identifier of the Wallet Provider.
 */
@property (nonatomic, copy, readonly, nullable) NSString *walletId;


/**
 * Returns array of account range start numbers that are enabled for the token requestor. The start numbers will be 19 digits in length.
 *
 * @return List of account range start numbers.
 */
@property (nonatomic, copy, readonly, nullable) NSArray *enabledAccountRanges;

/**
 * Returns array of the push methods supported by the token requestor.
 *
 * @return Supported push methods as array of MppPushMethod objects.
 */
@property (nonatomic, copy, readonly, nullable) NSArray *supportedPushMethods;

/**
 * Returns flag to indicate if token requestor supports multiple push receipts in a single request.
 *
 * @return true if token requestor supports multiple push receipts in a single request, false otherwise
 */
@property (nonatomic, assign, readonly) BOOL supportsMultiplePushedCards;

/**
 * @name MppTokenRequestor methods
 */

/**
 * Constructs Token Requestor from values passed in dictionary.
 *
 * @param dictionary Dictionary containing values to create a Token Requestor.
 *
 * @return Token Requestor.
 */
+ (instancetype)tokenRequestorWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if given Token Requestor is valid.
 *
 * @return Bool value if given Token Requestor is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

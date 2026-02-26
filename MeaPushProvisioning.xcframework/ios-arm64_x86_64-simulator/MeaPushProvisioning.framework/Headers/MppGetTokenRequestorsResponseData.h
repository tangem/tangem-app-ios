//
//  MppGetTokenRequestorsResponseData.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MppTokenRequestor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Class tokens requestors response.
 */
@interface MppGetTokenRequestorsResponseData : NSObject

/**
 * @name MppGetTokenRequestorsResponseData properties
 */

/**
 * Returns array of token requestors.
 *
 * @return Array of token requestors.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray *tokenRequestors;

/**
 * @name MppGetTokenRequestorsResponseData methods
 */

/**
 * Create get token requestors response data with dictionary.
 *
 * @param dictionary Dictionary containing records to create instance of MppGetTokenRequestorsResponseData.
 *
 * @return MppGetTokenRequestorsResponseData object instance.
 */
+ (instancetype)responseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if get token requestors response data is valid.
 *
 * @return Bool value if get token requestors response data is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

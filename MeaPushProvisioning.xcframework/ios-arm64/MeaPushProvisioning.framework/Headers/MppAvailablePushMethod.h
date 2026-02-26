//
//  MppAvailablePushMethod.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class describing available push methods.
 */
@interface MppAvailablePushMethod : NSObject

/**
 * @name MppAvailablePushMethod properties
 */

/**
 * The push method type of the URI. Issuer must respect specific rules when selecting the URI where they will send the consumer. Because mobile
 * apps provide a better mobile experience than the web browsers, Issuers should always try and direct the consumer to iOS app
 * of the Token Requestor, when possible.
 *
 * @return The push method type.
 */
@property (nonatomic, copy, readonly, nullable) NSString *type;

/**
 * The URI to open the token requestor's application or website.
 *
 * @return The URI to open the token requestor's application or website.
 */
@property (nonatomic, copy, readonly, nullable) NSString *uri;

/**
 * @name MppAvailablePushMethod methods
 */

/**
 * Constructs push method from values passed in dictionary.
 *
 * @param dictionary Dictionary containing `type` and `uri` to create a push method.
 *
 * @return Available push method.
 */
+ (instancetype)availablePushMethodWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if given push method is valid.
 *
 * To pass verification, `type` and `uri` of the push method should be valid.
 *
 * @return Bool value if given push method is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

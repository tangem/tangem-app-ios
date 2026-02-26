//
//  MppCompleteOemTokenizationResponseData.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class describing complete oem tokenization response data.
 */
@interface MppCompleteOemTokenizationResponseData : NSObject

/**
 * @name MppCompleteOemTokenizationResponseData properties
 */

/**
 * Encrypted pass data.
 *
 * @return Encrypted pass data.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *encryptedPassData;

/**
 * Activation data.
 *
 * @return Activation data.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *activationData;

/**
 * Ephemeral public key.
 *
 * @return Ephemeral public key.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *ephemeralPublicKey;

/**
 * PK add payment request.
 *
 * @return PK add payment request.
 */
@property (nonatomic, copy, readonly, nullable) PKAddPaymentPassRequest *addPaymentPassRequest;

/**
 * @name MppCompleteOemTokenizationResponseData methods
 */

/**
 * Create complete tokenization response data.
 *
 * @param encryptedPassData Encrypted pass data.
 * @param activationData Activation data.
 * @param ephemeralPublicKey Ephemeral public key.
 *
 * @return MppCompleteOemTokenizationResponseData object instance.
 */
+ (instancetype)responseDataWithEncryptedPassData:(NSString *_Nonnull)encryptedPassData
                                   activationData:(NSString *_Nonnull)activationData
                               ephemeralPublicKey:(NSString *_Nonnull)ephemeralPublicKey;

/**
 * Create complete tokenization response data with dictionary.
 *
 * @param dictionary Dictionary containing records to create instance of MppCompleteOemTokenizationResponseData.
 *
 * @return MppCompleteOemTokenizationResponseData object instance.
 */
+ (instancetype)responseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if complete tokenization response data is valid.
 *
 * @return Bool value if tokenization data is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

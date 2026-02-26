//
//  MppInitializeOemTokenizationResponseData.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class describing initialize oem tokenization response.
 */
@interface MppInitializeOemTokenizationResponseData : NSObject

/**
 * @name MppInitializeOemTokenizationResponseData properties
 */

/**
 * Receipt value to be passed to the token requestor. In case of Mastercard the pushAccountReceipt expires after 30 minutes.
 *
 * @return Tokenization receipt.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *tokenizationReceipt;

/**
 * Primary account suffix
 *
 * @return Primary account suffix.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *primaryAccountSuffix;

/**
 * Returns card payment network.
 *
 * @return Card payment network.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *networkName;

/**
 * Returns cardholder name.
 *
 * @return Cardholder name.
 */
@property (nonatomic, copy, readonly, nullable) NSString *cardholderName;

/**
 * Returns localized description.
 *
 * @return Localized description.
 */
@property (nonatomic, copy, readonly, nullable) NSString *localizedDescription;

/**
 * Returns primary account identifier.
 *
 * @return Primary acount identifier.
 */
@property (nonatomic, copy, readonly, nullable) NSString *primaryAccountIdentifier;

/**
 * Returns valid for.
 *
 * @return Valid for.
 */
@property (nonatomic, assign, readonly) NSUInteger validFor;


/**
 * Returns add payment pass request configuration.
 *
 * @return Add payment pass request configuration.
 */
@property (nonatomic, copy, readonly, nullable) PKAddPaymentPassRequestConfiguration *addPaymentPassRequestConfiguration;

/**
 * Returns encryption scheme.
 *
 * @return Encryption scheme.
 */
@property (nonatomic, copy, readonly, nonnull) PKEncryptionScheme encryptionScheme;

/**
 * Returns payment network.
 *
 * @return Payment network.
 */
@property (nonatomic, copy, readonly, nonnull) PKPaymentNetwork paymentNetwork;

/**
 * @name MppInitializeOemTokenizationResponseData methods
 */

/**
 * Create initialize oem tokenization response data.
 *
 * @param tokenizationReceipt Tokenization receipt.
 * @param primaryAccountSuffix Primary account suffix.
 * @param networkName Network name.
 * @param cardholderName Cardholder name.
 * @param localizedDescription Localizde description.
 * @param primaryAccountIdentifier Primary account identifier.
 * @param validFor Valid for..
 *
 * @return MppInitializeOemTokenizationResponseData object instance.
 */
+ (instancetype)responseDataWithTokenizationReceipt:(NSString *_Nonnull)tokenizationReceipt
                               primaryAccountSuffix:(NSString *_Nonnull)primaryAccountSuffix
                                        networkName:(NSString *_Nonnull)networkName
                                     cardholderName:(NSString *_Nullable)cardholderName
                               localizedDescription:(NSString *_Nullable)localizedDescription
                           primaryAccountIdentifier:(NSString *_Nullable)primaryAccountIdentifier
                                           validFor:(NSUInteger)validFor;

/**
 * Create initialize oem tokenization response data with dictionary.
 *
 * @param dictionary Dictionary containing records to create instance of MppInitializeOemTokenizationResponseData.
 *
 * @return MppInitializeOemTokenizationResponseData object instance.
 */
+ (instancetype)responseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if initialize oem tokenization response data is valid.
 *
 * @return Bool value if initialize oem tokenization response data is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

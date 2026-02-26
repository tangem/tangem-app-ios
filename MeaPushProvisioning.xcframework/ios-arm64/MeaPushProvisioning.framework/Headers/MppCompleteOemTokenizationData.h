//
//  MppCompleteOemTokenizationData.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class describing complete oem tokenization data.
 */
@interface MppCompleteOemTokenizationData : NSObject

/**
 * @name MppCompleteOemTokenizationData properties
 */

/**
 * Receipt value to be passed to the token requestor. In case of Mastercard the pushAccountReceipt expires after 30 minutes.
 *
 * @return Tokenization receipt.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *tokenizationReceipt;

/**
 * Certificates.
 *
 * @return Certificates.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<NSData *> *certificates;

/**
 * Number used once.
 *
 * @return A `nonce`.
 */
@property (nonatomic, copy, readonly, nonnull) NSData *nonce;

/**
 * Signature of number used once.
 *
 * @return A Signature of `nonce`.
 */
@property (nonatomic, copy, readonly, nonnull) NSData *nonceSignature;


/**
 * @name MppCompleteOemTokenizationData methods
 */

/**
 * Create tokenization data with tokenization receipt.
 *
 * @param tokenizationReceipt  Receipt value to be passed to the token requestor.
 * @param certificates  Certificates added to complete oem tokenization request.
 * @param nonce  Number used once.
 * @param nonceSignature  Signature of the `nonce`.
 *
 * @return MppCompleteOemTokenizationData object instance.
 */
+ (instancetype)tokenizationDataWithTokenizationReceipt:(NSString *_Nonnull)tokenizationReceipt
                                           certificates:(NSArray<NSData *> *_Nonnull)certificates
                                                  nonce:(NSData *_Nonnull)nonce
                                         nonceSignature:(NSData *_Nonnull)nonceSignature;

/**
 * Verify if tokenization data is valid.
 *
 * @return Bool value if tokenization data is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

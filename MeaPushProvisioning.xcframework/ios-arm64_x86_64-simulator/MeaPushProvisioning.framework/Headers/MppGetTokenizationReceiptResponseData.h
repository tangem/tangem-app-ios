//
//  MppGetTokenizationReceiptResponseData.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MeaPushProvisioning/MppAvailablePushMethod.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class describing tokenization receipt response.
 */
@interface MppGetTokenizationReceiptResponseData : NSObject

/**
 * @name MppGetTokenizationReceiptResponseData properties
 */

/**
 * Receipt value to be passed to the token requestor. In case of Mastercard the pushAccountReceipt expires after 30 minutes.
 *
 * @return Tokenization receipt.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *receipt;

/**
 * Array of push methods supported by the token requestor. Returns up to 3 URIs – with a minimum of 1 URI.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<MppAvailablePushMethod *> *availablePushMethods;

/**
 * Returns last four digits of payment card number.
 *
 * @return Last four digits of payment card number.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *lastFourDigits;

/**
 * Returns card payment network.
 *
 * @return Card payment network.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *paymentNetwork;

/**
 * @name MppGetTokenizationReceiptResponseData methods
 */

/**
 * Create tokenization receipt response data with dictionary.
 *
 * @param dictionary Dictionary containing records to create instance of MppGetTokenizationReceiptResponseData.
 *
 * @return MppGetTokenizationReceiptResponseData object instance.
 */
+ (instancetype)responseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;

/**
 * Verify if tokenization receipt response data is valid.
 *
 * @return Bool value if tokenization receipt response data is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END

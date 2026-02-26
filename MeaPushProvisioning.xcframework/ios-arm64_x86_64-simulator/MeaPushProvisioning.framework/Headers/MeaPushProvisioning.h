//
//  MeaPushProvisioning.h
//  MeaPushProvisioning
//
//  Copyright © 2019 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#import <MeaPushProvisioning/MppCardDataParameters.h>
#import <MeaPushProvisioning/MppCompleteOemTokenizationData.h>
#import <MeaPushProvisioning/MppCompleteOemTokenizationResponseData.h>
#import <MeaPushProvisioning/MppInitializeOemTokenizationResponseData.h>
#import <MeaPushProvisioning/MppGetTokenRequestorsResponseData.h>
#import <MeaPushProvisioning/MppGetTokenizationReceiptResponseData.h>
#import <MeaPushProvisioning/MppIntent.h>
#import <MeaPushProvisioning/MppConsumerInformation.h>
#import <MeaPushProvisioning/MppBillingAddress.h>
#import <MeaPushProvisioning/MppPushResponseData.h>
#import <MeaPushProvisioning/MppCheckResponseData.h>
#import <MeaPushProvisioning/MppConsumerRequestStatus.h>
#import <MeaPushProvisioning/MppConsumerRequestDetail.h>
#import <MeaPushProvisioning/MppConsumerDetails.h>
#import <MeaPushProvisioning/MppCard.h>
#import <MeaPushProvisioning/MppGetAssetResponseData.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides API for interaction with the MeaPushProvisioning library using class methods.
 */
@interface MeaPushProvisioning : NSObject

@property (class, readonly) NSString *ClickToPay;

#pragma mark - Configuration

/**
 * Returns payment app instance id.
 *
 * Method returns `paymentAppInstanceId` if it exists or generates a new one.
 *
 * @return Payment app instance id.
 */
+ (NSString *_Nonnull)paymentAppInstanceId;

/**
 * Loads provided client configuration file.
 *
 * @param configFileName  File name of the provided client configuration file.
 */
+ (void)loadConfig:(NSString *_Nonnull)configFileName;

/**
 * Returns hash of the loaded configuration.
 *
 * @return hash of the loaded configuration or an empty string when configuration is not loaded.
 */
+ (NSString *_Nonnull)configurationHash;

/**
 * Returns version code of the SDK.
 *
 * @return Version code.
 */
+ (NSString *)versionCode;

/**
 * Returns version name of the SDK.
 *
 * Example: "mpp-test-1.0.0"
 *
 * @return Version name.
 */
+ (NSString *)versionName;

/**
 * Switch enable/disable debug logging.
 *
 * @param enabled  Enable or disable debug logging.
 */
+ (void)setDebugLoggingEnabled:(BOOL)enabled;

#pragma mark - In-App Provisioning

/**
 * Initiate in-app push provisioning with MppCardDataParameters parameter.
 *
 * Check if the payment card can be added to Apple Pay by using primaryAccountIdentifier in response.
 *
 * @param cardDataParameters Card data parameters as instance of MppCardDataParameters containing the card information.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppInitializeOemTokenizationResponseData `*_Nullable data` -Initialization response data in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)initializeOemTokenization:(MppCardDataParameters *_Nonnull)cardDataParameters
                completionHandler:(void (^)(MppInitializeOemTokenizationResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Complete in-app push provisioning. Exchanges Apple certificates and signature with Issuer Host.
 *
 * Delegate should implement `PKAddPaymentPassViewControllerDelegate` protocol to call completeOemTokenization:completionHandler: method,
 * once the data is exchanged `PKAddPaymentPassRequest` is passed to the handler to add the payment card to Apple Wallet.
 * In the end and delegate method is invoked to inform you if request has succeeded or failed.
 *
 * @param tokenizationData Card data parameters as instance of MppCardDataParameters containing the card information.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppCompleteOemTokenizationResponseData `*_Nullable data` - Completition response data in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)completeOemTokenization:(MppCompleteOemTokenizationData *_Nonnull)tokenizationData
              completionHandler:(void (^)(MppCompleteOemTokenizationResponseData *_Nullable data, NSError *_Nullable error))completionHandler;


/**
 * Method gets activation data (cryptographic OTP) for the Secure Element pass activation via ``activateSecureElementPass:withActivationData:completionHandler:``
 *
 * @param cardDataParameters Card data parameters as instance of MppCardDataParameters containing the card information.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - `NSString *_Nullable activationData` - Activation data string in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)getActivationData:(MppCardDataParameters *_Nonnull)cardDataParameters
        completionHandler:(void (^)(NSString *_Nullable activationData, NSError *_Nullable error))completionHandler API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Activates a Secure Element pass using Activation Data.
 *
 * @param secureElementPass The Secure Element pass to activate.
 * @param activationData A cryptographic value that the activation process requires as hex string.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - `BOOL success` - `true` if the pass activates; otherwise, `false`
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)activateSecureElementPass:(PKSecureElementPass *_Nonnull)secureElementPass
               withActivationData:(NSString *_Nonnull)activationData
                completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Activates a Secure Element pass.
 *
 * @param secureElementPass The Secure Element pass to activate.
 * @param paymentNetwork    Paymenent network.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - `BOOL success` - `true` if the pass activates; otherwise, `false`
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)activateSecureElementPass:(PKSecureElementPass *_Nonnull)secureElementPass
               withPaymentNetwork:(PKPaymentNetwork _Nonnull)paymentNetwork
                completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Verify if primaryAccountIdentifier can be used to add payment pass to iPhone Wallet and/or Watch.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if payment pass can be added with given primaryAccountIdentifier.
 */
+ (BOOL)canAddSecureElementPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Verify if primaryAccountNumberSuffix can be used to add payment pass. Check is specific for iPhone Wallet.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if payment pass can be added with given primaryAccountNumberSuffix.
 */
+ (BOOL)canAddSecureElementPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Verify if payment pass exists with primaryAccountIdentifier. Check is specific for iPhone Wallet.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if payment pass exists with given primaryAccountIdentifier.
 */
+ (BOOL)secureElementPassExistsWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4));

/**
 * Verify if remote payment pass exists with primaryAccountIdentifier. Check is specific for Watch. Call when watch is paired.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if remote payment pass exists with given primaryAccountIdentifier.
 */
+ (BOOL)remoteSecureElementPassExistsWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Verify if payment pass exists with primaryAccountNumberSuffix. Check is specific for iPhone.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if payment pass exists with given primaryAccountNumberSuffix.
 */
+ (BOOL)secureElementPassExistsWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix  API_AVAILABLE(ios(13.4));

/**
 * Verify if remote payment pass exists with primaryAccountNumberSuffix. Check is specific for Watch. Call when watch is paired.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if remote payment pass exists with given primaryAccountNumberSuffix.
 */
+ (BOOL)remoteSecureElementPassExistsWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Returns secure element pass with primaryAccountIdentifier.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if remote secure element can be added with given primaryAccountIdentifier. Returns true if Watch is not paired.
 */
+ (PKSecureElementPass *)secureElementPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Returns secure element pass with primaryAccountNumberSuffix.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if payment pass can be added with given primaryAccountNumberSuffix. Returns true if Watch is not paired.
 */
+ (PKSecureElementPass *)secureElementPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Returns secure element pass with primaryAccountIdentifier.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return remote secure element pass.
 */
+ (PKSecureElementPass *)remoteSecureElementPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Returns remote secure element pass with primaryAccountNumberSuffix.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return remote secure element pass.
 */
+ (PKSecureElementPass *)remoteSecureElementPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Returns secure element pass with serialNumber.
 *
 * @param serialNumber Serial number.
 *
 * @return secure element pass.
 */
+ (PKSecureElementPass *)secureElementPassWithSerialNumber:(NSString *_Nonnull)serialNumber API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Returns remote secure element pass with serialNumber.
 *
 * @param serialNumber Serial number.
 *
 * @return remote secure element pass.
 */
+ (PKSecureElementPass *)remoteSecureElementPassWithSerialNumber:(NSString *_Nonnull)serialNumber API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Presents a Secure Element pass with Primary Account Identifier.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 */
+ (void)presentSecureElementPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Presents a Secure Element pass with PAN Suffix.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 */
+ (void)presentSecureElementPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Checks if Watch is paired.
 *
 * @param completion The code block invoked when request is completed. Returns true if Watch is paired.
 *
 */
+ (void)isWatchPaired:(void(^)(BOOL paired))completion;

/**
 * Checks if remote payment pass with primaryAccountIdentifier can be added.
 *
 * @return Bool value if payment pass can be added with given primaryAccountIdentifier. Returns true if Watch is not paired.
 */
+ (BOOL)canAddRemoteSecureElementPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Checks if remote payment pass with primaryAccountNumberSuffix can be added.
 *
 * @return Bool value if payment pass can be added with given primaryAccountNumberSuffix. Returns true if Watch is not paired.
 */
+ (BOOL)canAddRemoteSecureElementPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Checks if remote payment pass with primaryAccountIdentifier can be added.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 * @param completion The code block invoked when request is completed, with Boolean argument set to true if remote payment pass can be added.
 */
+ (void)canAddRemoteSecureElementPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier completion:(void(^)(BOOL canAdd))completion API_AVAILABLE(ios(13.4), watchos(6.4));

/**
 * Checks if remote payment pass with primaryAccountNumberSuffix can be added.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 * @param completion The code block invoked when request is completed, with Boolean argument set to true if remote payment pass can be added.
 */
+ (void)canAddRemoteSecureElementPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix completion:(void(^)(BOOL canAdd))completion API_AVAILABLE(ios(13.4), watchos(6.4));


/**
 * Passes in the user’s pass library that the app can access.
 *
 * @return Passes in the user’s pass library that the app can access.
 */
+ (NSArray<PKPass *> *)passes;

/**
 * Secure Element passes that PassKit stores on paired devices that the app can access.
 *
 * @return Secure Element passes that PassKit stores on paired devices.
 *
 */
+ (NSArray<PKSecureElementPass *> *)remoteSecureElementPasses API_AVAILABLE(ios(13.4), watchos(6.4));


#pragma mark - Token Requestor

/**
 * Retrieves eligible Token Requestors which support push provisioning for provided card data.
 *
 * Once list of requestors is received, user has an option to select the one to be used.
 *
 * @param cardDataParameters Card data parameters as instance of MppCardDataParameters containing the card information to be provisioned by the token requestor.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppGetTokenRequestorsResponseData `*_Nullable data` - Eligible Token Requestors in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)getEligibleTokenRequestors:(MppCardDataParameters *_Nonnull)cardDataParameters
                 completionHandler:(void (^)(MppGetTokenRequestorsResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Retrieves eligible Token Requestors which support push provisioning for provided cards.
 *
 * Once list of requestors is received, user has an option to select the one to be used.
 *
 * @param cards Array of the cards to retrieve the eligible token requestors for.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppGetTokenRequestorsResponseData `*_Nullable data` - Eligible Token Requestors in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)getEligibleTokenRequestorsForCards:(NSArray<MppCardDataParameters *> *_Nonnull)cards
                         completionHandler:(void (^)(MppGetTokenRequestorsResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Retrieves eligible Token Requestors which support push provisioning for provided account ranges.
 *
 * Once list of requestors is received, user has an option to select the one to be used.
 *
 * @param accountRanges Array of the starting numbers of the account ranges to retrieve the eligible token requestors for.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppGetTokenRequestorsResponseData `*_Nullable tokenRequestors` - Eligible Token Requestors in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)getEligibleTokenRequestorsForAccountRanges:(NSArray<NSString *> *_Nonnull)accountRanges
                                 completionHandler:(void (^)(MppGetTokenRequestorsResponseData *_Nullable data, NSError *_Nullable error))completionHandler;


/**
 * Gets static Assets such as: Card art, Mastercard brand logos, Issuers logos.
 * Every Asset in the repository is referenced using an assetId.
 *
 * @param assetId           Asset Id value used to reference an Asset.
 * @param completionHandler The code block invoked when request is completed.
 */
+ (void)getAsset:(NSString* _Nonnull)assetId
completionHandler:(void (^)(MppGetAssetResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Pushes particular card data to a selected Token Requestor.
 *
 * Token Requestor selection is done from the list of eligible Token Requestors
 * previously returned by getTokenRequestors:completionHandler: method. In response Token Requestor will return a receipt, which needs to be
 * provided to a merchant or any other instance where the card will be digitized in. Receipt can be a deep-link to a bank's or merchant
 * application, and it can also be a URL to a web page.
 *
 * @param tokenRequestorId Identifies the Token Requestor, received from getTokenRequestors:completionHandler: method.
 * @param cardDataParameters Card data parameters as instance of MppCardDataParameters containing the card information to be provisioned by the token requestor.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppGetTokenizationReceiptResponseData `*_Nullable data` - Tokenization receipt data in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)getTokenizationReceipt:(NSString *_Nonnull)tokenRequestorId
            cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
             completionHandler:(void (^)(MppGetTokenizationReceiptResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Pushes particular card data to a selected Token Requestor.
 *
 * Token Requestor selection is done from the list of eligible Token Requestors
 * previously returned by getTokenRequestors:completionHandler: method. In response Token Requestor will return a receipt, which needs to be
 * provided to a merchant or any other instance where the card will be digitized in. Receipt can be a deep-link to a bank's or merchant
 * application, and it can also be a URL to a web page.
 *
 * @param tokenRequestorId   Identifies the Token Requestor, received from getTokenRequestors:completionHandler: method.
 * @param cardDataParameters Card data parameters as instance of MppCardDataParameters containing the card information to be provisioned by the token requestor.
 * @param intent             Optional, required for VISA. The intent helps VCEH to determine the relevant user experience.
 *                          PUSH_PROV_MOBILE, PUSH_PROV_ONFILE - Synchronous flow. Enrollment of card credentials is completed as part of the same session on the same device as issuer and TR.
 *                          PUSH_PROV_CROSS_USER, PUSH_PROV_CROSS_DEVICE - Asynchronous flow.
 * @param completionHandler The code block invoked when request is completed.
 *
 *      Parameters for the `completionHandler`:
 *
 *      - MppGetTokenizationReceiptResponseData `*_Nullable data` - Tokenization receipt data in case of success
 *      - `NSError *_Nullable error` - Error object in case of failure
 */
+ (void)getTokenizationReceipt:(NSString *_Nonnull)tokenRequestorId
            cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
                        intent:(MppIntent) intent
             completionHandler:(void (^)(MppGetTokenizationReceiptResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Checks if specified card is added to selected Token Requestor / Click to Pay.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param cardDataParameters    Card data parameters as instance of MppCardDataParameters containing the card information.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)check:(NSString *_Nullable)tokenRequestorId
cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
completionHandler:(void (^)(MppCheckResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Pushes (enroll) specified card to selected Token Requestor / Click to Pay.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param cardDataParameters    Card data parameters as instance of MppCardDataParameters containing the card information.
 * @param consumerInformation   Consumer information.
 * @param billingAddress        Billing address.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)push:(NSString *_Nullable)tokenRequestorId
cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
consumerInformation:(MppConsumerInformation *_Nonnull)consumerInformation
billingAddress:(MppBillingAddress *_Nonnull)billingAddress
completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Retrieves consumer and cards (payment instrument) information.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param externalConsumerId    External consumer Id.
 * @param completionHandler     The code block invoked when request is completed.
 * @deprecated Use `getConsumerDetails:paymentNetwork:externalConsumerId:externalConsumerId:completionHandler:` instead.
 */
+ (void)getConsumerDetails:(NSString *_Nullable)tokenRequestorId
        externalConsumerId:(NSString *_Nonnull)externalConsumerId
         completionHandler:(void (^)(MppConsumerDetails *_Nullable data, NSError *_Nullable error))completionHandler
__deprecated_msg("use 'getConsumerDetails:paymentNetwork:externalConsumerId:externalConsumerId:completionHandler:' instead.");

/**
 * Retrieves consumer and cards (payment instrument) information.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param paymentNetwork        Payment Network.
 * @param externalConsumerId    External consumer Id.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)getConsumerDetails:(NSString *_Nullable)tokenRequestorId
            paymentNetwork:(PKPaymentNetwork _Nonnull)paymentNetwork
        externalConsumerId:(NSString *_Nonnull)externalConsumerId
         completionHandler:(void (^)(MppConsumerDetails *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Retrieves consumer request status.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param requestTraceId        Request trace Id.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)getConsumerRequestStatus:(NSString *_Nullable)tokenRequestorId
                  requestTraceId:(NSString *_Nonnull)requestTraceId
               completionHandler:(void (^)(MppConsumerRequestStatus *_Nullable consumerRequestStatus, NSError *_Nullable error))completionHandler;

/**
 * Updates the consumer information such as customer name, email, or phone number.
 * This method is applicable for Enrolled consumers only.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param consumerInformation   Consumer information.
 * @param completionHandler     The code block invoked when request is completed.
 * @deprecated Use `updateConsumerDetails:paymentNetwork:consumerInformation:completionHandler:` instead.
 */
+ (void)updateConsumerDetails:(NSString *_Nullable)tokenRequestorId
          consumerInformation:(MppConsumerInformation *_Nonnull)consumerInformation
            completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler
__deprecated_msg("Use 'updateConsumerDetails:paymentNetwork:consumerInformation:completionHandler:' instead.");

/**
 * Updates the consumer information such as customer name, email, or phone number.
 * This method is applicable for Enrolled consumers only.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param paymentNetwork        Payment Network.
 * @param consumerInformation   Consumer information.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)updateConsumerDetails:(NSString *_Nullable)tokenRequestorId
               paymentNetwork:(PKPaymentNetwork _Nonnull)paymentNetwork
          consumerInformation:(MppConsumerInformation *_Nonnull)consumerInformation
            completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler;
/**
 * Deletes consumer information and all cards (payment instruments) related to the profile.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param externalConsumerId    External consumer Id.
 * @param completionHandler     The code block invoked when request is completed.
 * @deprecated  Use `deleteConsumer:paymentNetwork:externalConsumerId:completionHandler:` instead.
 */
+ (void)deleteConsumer:(NSString *_Nullable)tokenRequestorId
    externalConsumerId:(NSString *_Nonnull)externalConsumerId
     completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler
__deprecated_msg("Use 'deleteConsumer:paymentNetwork:externalConsumerId:completionHandler:' instead.");

/**
 * Deletes consumer information and all cards (payment instruments) related to the profile.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param paymentNetwork        Payment Network.
 * @param externalConsumerId    External consumer Id.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)deleteConsumer:(NSString *_Nullable)tokenRequestorId
        paymentNetwork:(PKPaymentNetwork _Nonnull)paymentNetwork
    externalConsumerId:(NSString *_Nonnull)externalConsumerId
     completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler;
/**
 * Updates card details.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param externalConsumerId    External consumer Id.
 * @param cardDataParameters    Card data object containing the card information.
 * @param cardholderName        Cardholder name.
 * @param expiryYear            Expiry year.
 * @param expiryMonth           Expiry month.
 * @param billingAddress        Billing address.
 * @param completionHandler     The code block invoked when request is completed.
 * @deprecated  Use `updateCardDetails:paymentNetwork:externalConsumerId:cardDataParameters:cardholderName:expiryYear:expiryMonth:billingAddress:externalCardId:completionHandler:` instead.
 */
+ (void)updateCardDetails:(NSString *_Nullable)tokenRequestorId
       externalConsumerId:(NSString *_Nonnull)externalConsumerId
       cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
           cardholderName:(NSString *_Nonnull)cardholderName
               expiryYear:(NSString *_Nonnull)expiryYear
              expiryMonth:(NSString *_Nonnull)expiryMonth
           billingAddress:(MppBillingAddress *_Nonnull)billingAddress
        completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler
__deprecated_msg("Use 'updateCardDetails:paymentNetwork:externalConsumerId:cardDataParameters:cardholderName:expiryYear:expiryMonth:billingAddress:externalCardId:completionHandler:' instead.");

/**
 * Updates card details.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param paymentNetwork        Payment Network.
 * @param externalConsumerId    External consumer Id.
 * @param cardDataParameters    Card data object containing the card information.
 * @param cardholderName        Cardholder name.
 * @param expiryYear            Expiry year.
 * @param expiryMonth           Expiry month.
 * @param billingAddress        Billing address.
 * @param externalCardId        External card id.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)updateCardDetails:(NSString *_Nullable)tokenRequestorId
           paymentNetwork:(PKPaymentNetwork _Nonnull)paymentNetwork
       externalConsumerId:(NSString *_Nonnull)externalConsumerId
       cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
           cardholderName:(NSString *_Nonnull)cardholderName
               expiryYear:(NSString *_Nonnull)expiryYear
              expiryMonth:(NSString *_Nonnull)expiryMonth
           billingAddress:(MppBillingAddress *_Nonnull)billingAddress
           externalCardId:(NSString *_Nullable)externalCardId
        completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

/**
 * Deletes card (payment instrument) information from consumer profile.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param externalConsumerId    External consumer Id.
 * @param cardDataParameters    Card data object containing the card information.
 * @param completionHandler     The code block invoked when request is completed.
 * @deprecated  Use `deleteCard:paymentNetwork:externalConsumerId:cardDataParameters:externalCardId:completionHandler:` instead.
 */
+ (void)deleteCard:(NSString *_Nullable)tokenRequestorId
externalConsumerId:(NSString *_Nonnull)externalConsumerId
cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
 completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler
__deprecated_msg("Use 'deleteCard:paymentNetwork:externalConsumerId:cardDataParameters:externalCardId:completionHandler:' instead.");

/**
 * Deletes card (payment instrument) information from consumer profile.
 *
 * @param tokenRequestorId      `MeaPushProvisioning.ClickToPay` or eligible Token Requestor Id.
 * @param paymentNetwork        Payment Network.
 * @param externalConsumerId    External consumer Id.
 * @param cardDataParameters    Card data object containing the card information.
 * @param externalCardId        External card Id.
 * @param completionHandler     The code block invoked when request is completed.
 */
+ (void)deleteCard:(NSString *_Nullable)tokenRequestorId
    paymentNetwork:(PKPaymentNetwork _Nonnull)paymentNetwork
externalConsumerId:(NSString *_Nonnull)externalConsumerId
cardDataParameters:(MppCardDataParameters *_Nonnull)cardDataParameters
    externalCardId:(NSString *_Nullable)externalCardId
 completionHandler:(void (^)(MppPushResponseData *_Nullable data, NSError *_Nullable error))completionHandler;

#pragma mark - Deprecated since iOS 13.4

/**
 * @name Deprecated since iOS 13.4
 */

/**
 * Verify if primaryAccountIdentifier can be used to add payment pass to  iPhone Wallet and/or Watch.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if payment pass can be added with given primaryAccountIdentifier.
 */
+ (BOOL)canAddPaymentPassWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_DEPRECATED("Use +[MeaPushProvisioning canAddSecureElementPassWithPrimaryAccountIdentifier:] instead", ios(9.0, 13.4), watchos(2.0, 6.2));

/**
 * Verify if primaryAccountNumberSuffix can be used to add payment pass. Check is specific for iPhone.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if payment pass can be added with given primaryAccountNumberSuffix.
 */
+ (BOOL)canAddPaymentPassWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_DEPRECATED("Use +[MeaPushProvisioning canAddSecureElementPassWithPrimaryAccountNumberSuffix:] instead", ios(9.0, 13.4), watchos(2.0, 6.2));

/**
 * Verify if payment pass exists with primaryAccountIdentifier. Check is specific for iPhone.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if payment pass exists with given primaryAccountIdentifier.
 */
+ (BOOL)paymentPassExistsWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_DEPRECATED("Use +[MeaPushProvisioning secureElementPassExistsWithPrimaryAccountIdentifier:] instead", ios(10.0, 13.4));

/**
 * Verify if remote payment pass exists with primaryAccountIdentifier. Check is specific for Watch. Call when watch is paired.
 *
 * @param primaryAccountIdentifier Primary account identifier returned by initializeOemTokenization:completionHandler: method in [MppInitializeOemTokenizationResponseData primaryAccountIdentifier] property.
 *
 * @return Bool value if remote payment pass exists with given primaryAccountIdentifier.
 */
+ (BOOL)remotePaymentPassExistsWithPrimaryAccountIdentifier:(NSString *_Nonnull)primaryAccountIdentifier API_DEPRECATED("Use +[MeaPushProvisioning remoteSecureElementPassExistsWithPrimaryAccountIdentifier:] instead", ios(9.0, 13.4), watchos(2.0, 6.2));

/**
 * Verify if payment pass exists with primaryAccountNumberSuffix. Check is specific for iPhone.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if payment pass exists with given primaryAccountNumberSuffix.
 */
+ (BOOL)paymentPassExistsWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_DEPRECATED("Use +[MeaPushProvisioning secureElementPassExistsWithPrimaryAccountNumberSuffix:] instead", ios(9.0, 13.4));

/**
 * Verify if remote payment pass exists with primaryAccountNumberSuffix. Check is specific for Watch. Call when watch is paired.
 *
 * @param primaryAccountNumberSuffix PAN suffix.
 *
 * @return Bool value if remote payment pass exists with given primaryAccountNumberSuffix.
 */
+ (BOOL)remotePaymentPassExistsWithPrimaryAccountNumberSuffix:(NSString *_Nonnull)primaryAccountNumberSuffix API_DEPRECATED("Use +[MeaPushProvisioning remoteSecureElementPassExistsWithPrimaryAccountNumberSuffix:] instead", ios(9.0, 13.4), watchos(2.0, 6.2));

+ (void)setSdkProperties:(NSDictionary *_Nonnull)properties;

@end

NS_ASSUME_NONNULL_END

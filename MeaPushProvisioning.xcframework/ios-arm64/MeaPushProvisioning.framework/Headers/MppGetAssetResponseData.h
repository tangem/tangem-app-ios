//
// MppGetAssetResponseData.h
// MeaPushProvisioning
//
// Copyright © 2025 MeaWallet AS. All rights reserved.
//

#import <MeaPushProvisioning/MppAsset.h>
NS_ASSUME_NONNULL_BEGIN
/**
 * Token Requestor Asset
 */
@interface MppGetAssetResponseData : NSObject
/**
 * @name MppAsset properties
 */
/**
 * Returns array of assets.
 *
 * @return Array of assets
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<MppAsset*> *assets;
/**
 * @name MppGetAssetResponseData methods
 */
/**
 * Creates MppGetAssetResponseData with dictionary.
 *
 * @param dictionary Dictionary containing records to create instance of MppGetAssetResponseData.
 *
 * @return MppGetAssetResponseData object instance.
 */
+ (instancetype)assetResponseDataWithDictionary:(NSDictionary *_Nonnull)dictionary;
/**
 * Verify MppGetAssetResponseData instance is valid.
 *
 * @return true when MppGetAssetResponseData esponse data is valid.
 */
- (BOOL)isValid;
@end
NS_ASSUME_NONNULL_END

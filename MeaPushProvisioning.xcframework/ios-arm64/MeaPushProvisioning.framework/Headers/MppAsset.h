//
// MppAsset.h
// MeaPushProvisioning
//
// Copyright © 2025 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/**
 * Token Requestor Asset
 */
@interface MppAsset : NSObject
/**
 * @name MppAsset properties
 */
/**
 * MIME type.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *type;
/**
 * Height of an image.
 */
@property (nonatomic, readonly) NSInteger height;
/**
 * Width of an image.
 */
@property (nonatomic, readonly) NSInteger width;
/**
 * URL of an asset.
 */
@property (nonatomic, copy, readonly) NSURL *url;
/**
 * Constructs `MppAsset` from values passed in dictionary.
 *
 * @param dictionary Dictionary containing values to create a `MppAsset`.
 *
 * @return `MppAsset`.
 */
+ (instancetype)assetWithDictionary:(NSDictionary *_Nonnull)dictionary;
@end
NS_ASSUME_NONNULL_END

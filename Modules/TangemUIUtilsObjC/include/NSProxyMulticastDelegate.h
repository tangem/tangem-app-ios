//
//  NSProxyMulticastDelegate.h
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A multicast Objective-C delegate proxy built on top of `NSProxy`.
///
/// This proxy forwards Objective-C messages to two delegate objects:
/// - a custom delegate, provided at initialization time.
/// - an original delegate, captured later.
@interface NSProxyMulticastDelegate<TDelegate: id<NSObject>> : NSProxy

/// Creates a proxy with a custom delegate that will participate in message forwarding.
/// - Parameter customDelegate: A delegate object that provides additional behavior. The proxy retains this object for its lifetime.
- (instancetype)initWithCustomDelegate:(TDelegate)customDelegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Sets the original delegate that was previously installed on the target object.
///
/// This method is expected to be called exactly once, after the proxy is created and before it is installed as the active delegate.
///
/// - Parameter originalDelegate: The delegate originally used by the system or framework.
- (void)setOriginalDelegate:(TDelegate)originalDelegate NS_SWIFT_NAME(set(originalDelegate:));

@end

NS_ASSUME_NONNULL_END

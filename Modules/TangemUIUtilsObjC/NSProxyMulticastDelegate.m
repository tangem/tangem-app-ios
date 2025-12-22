//
//  NSProxyMulticastDelegate.m
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#import "NSProxyMulticastDelegate.h"

@interface NSProxyMulticastDelegate<TDelegate: id<NSObject>> ()

@property (nonatomic, strong, readonly) TDelegate customDelegate;
@property (nonatomic, weak, nullable) TDelegate originalDelegate;

@end

@implementation NSProxyMulticastDelegate

- (instancetype)initWithCustomDelegate:(id)customDelegate {
    NSParameterAssert(customDelegate != nil);

    _customDelegate = customDelegate;
    return self;
}

- (void)setOriginalDelegate:(id)originalDelegate {
    NSParameterAssert(originalDelegate != nil);
    NSAssert(_originalDelegate == nil, @"Original delegate has already been set. Developer mistake.");

    _originalDelegate = originalDelegate;
}

#pragma mark - Message Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([_originalDelegate respondsToSelector:aSelector]) {
        return YES;
    }

    if ([_customDelegate respondsToSelector:aSelector]) {
        return YES;
    }

    return NO;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    NSString * methodReturnType = [NSString stringWithCString:invocation.methodSignature.methodReturnType encoding:NSUTF8StringEncoding];
    BOOL methodReturnsVoid = [methodReturnType isEqualToString:@"v"];

    BOOL originalResponds = [_originalDelegate respondsToSelector:invocation.selector];
    BOOL customResponds = [_customDelegate respondsToSelector:invocation.selector];

    NSAssert(originalResponds || customResponds, @"Either of the delegates is expected to respond to the selector");

    // [REDACTED_USERNAME], we can invoke both delegates' invocation if method return type is `void`.
    if (methodReturnsVoid) {
        if (customResponds) [invocation invokeWithTarget:_customDelegate];
        if (originalResponds) [invocation invokeWithTarget:_originalDelegate];
        return;
    }

    // For non-void return type, we must pick a single true value. Original delegate has priority for now.
    // Update this behavior if needed.

    if (originalResponds) {
        [invocation invokeWithTarget:_originalDelegate];
        return;
    }

    if (customResponds) {
        [invocation invokeWithTarget:_customDelegate];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([_originalDelegate respondsToSelector:aSelector]) {
        return [[_originalDelegate class] instanceMethodSignatureForSelector:aSelector];
    }

    if ([_customDelegate respondsToSelector:aSelector]) {
        return [[_customDelegate class] instanceMethodSignatureForSelector:aSelector];
    }

    NSAssert(NO, @"Unexpected fallback. Developer mistake.");
    return nil;
}

@end

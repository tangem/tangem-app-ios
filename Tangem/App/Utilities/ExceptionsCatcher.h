//
//  ExceptionsCatcher.h
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

#ifndef ExceptionsCatcher_h
#define ExceptionsCatcher_h

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable nsTryCatch(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

#endif /* ExceptionsCatcher_h */

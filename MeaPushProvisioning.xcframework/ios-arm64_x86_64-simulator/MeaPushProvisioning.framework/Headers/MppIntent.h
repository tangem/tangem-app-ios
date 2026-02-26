//
//  MppIntent.h
//  MeaPushProvisioning
//
//  Copyright © 2022 MeaWallet AS. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef MppIntent_h
#define MppIntent_h

typedef NS_ENUM(NSInteger, MppIntent) {
    MPP_EMPTY_INTENT = 0,
    MPP_PUSH_PROV_MOBILE,
    MPP_PUSH_PROV_ONFILE,
    MPP_PUSH_PROV_CROSS_USER,
    MPP_PUSH_PROV_CROSS_DEVICE
};

#endif /* MppIntent_h */

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "fe.h"
#import "fixedint.h"
#import "ge.h"
#import "ed25519.h"
#import "precomp_data.h"
#import "sc.h"
#import "sha512.h"
#import "stellarsdk.h"

FOUNDATION_EXPORT double stellarsdkVersionNumber;
FOUNDATION_EXPORT const unsigned char stellarsdkVersionString[];


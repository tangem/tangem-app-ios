//
//  MobileSocialLoginProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import AuthenticationServices
import TangemFoundation
import TangemBackendAuthentication
import TangemSocialAuthentication
import TangemMobileWalletBackup
import class Alamofire.Interceptor

enum MobileSocialLoginProviderFactory {
    static func makeAppleSignInProvider() -> AppleSignInProvider {
        AppleSignInProvider(presentationAnchorProvider: {
            UIApplication.keyWindow ?? ASPresentationAnchor()
        })
    }

    static func makeProvider() -> SocialAuthProvider {
        CommonSocialAuthProvider(
            baseURL: AppEnvironment.current.backendAuthenticationBaseUrl,
            networkConfiguration: .ephemeralConfiguration,
            requestInterceptor: Interceptor(
                adapter: BackendAuthenticationAssembly.requestAdapter,
                retrier: BackendAuthenticationAssembly.requestRetrier
            ),
            backupManager: CommonMobileWalletSocialBackupManager(destination: .iCloud)
        )
    }
}

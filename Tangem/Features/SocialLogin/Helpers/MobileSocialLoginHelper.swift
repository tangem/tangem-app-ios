//
//  MobileSocialLoginHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup
import TangemSocialAuthentication

final class MobileSocialLoginHelper {
    private let backupManager: MobileWalletSocialBackupManager
    private weak var output: MobileSocialLoginOutput?

    init(
        backupManager: MobileWalletSocialBackupManager = CommonMobileWalletSocialBackupManager(destination: .iCloud),
        output: MobileSocialLoginOutput
    ) {
        self.backupManager = backupManager
        self.output = output
    }

    @discardableResult
    func signIn() async -> MobileSocialLoginResult {
        await output?.socialLoginLoading(true)
        let result = await performSignIn()
        await output?.socialLoginLoading(false)
        return result
    }
}

// MARK: - Private methods

private extension MobileSocialLoginHelper {
    func performSignIn() async -> MobileSocialLoginResult {
        var isSignInPresented = false

        do {
            let nonce = try await MobileSocialLoginProviderFactory.makeProvider().recoverNonce()

            guard !Task.isCancelled else { return .cancelled }
            await output?.socialLoginWillPresentSignIn()
            isSignInPresented = true
            let credentials = try await MobileSocialLoginProviderFactory.makeAppleSignInProvider().signIn(nonce: nonce)

            await output?.socialLoginProcessing(true)
            let hasBackup = await hasBackup()
            await output?.socialLoginProcessing(false)

            let input = MobileSocialWalletInput(credentials: credentials, hasBackup: hasBackup)
            await output?.socialLoginCompleted(input: input)
            return .completed
        } catch SocialAuthError.cancelled {
            return .cancelled
        } catch {
            AppLogger.error("Social login failed", error: error)
            guard !Task.isCancelled else { return .cancelled }
            await output?.socialLoginProcessing(false)
            await output?.socialLoginFailed(failure: .somethingWentWrong)
            return .failed(isSignInPresented: isSignInPresented)
        }
    }

    func hasBackup() async -> Bool {
        do {
            return try await backupManager.hasBackup()
        } catch {
            AppLogger.error("Social login backup check failed", error: error)
            return false
        }
    }
}

// MARK: - Result

enum MobileSocialLoginResult {
    case completed
    case cancelled
    case failed(isSignInPresented: Bool)
}

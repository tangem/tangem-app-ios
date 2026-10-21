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

    func signIn() async {
        await output?.socialLoginLoading(true)

        do {
            let nonce = try await MobileSocialLoginProviderFactory.makeProvider().recoverNonce()

            guard !Task.isCancelled else { return }
            await output?.socialLoginWillPresentSignIn()
            let credentials = try await MobileSocialLoginProviderFactory.makeAppleSignInProvider().signIn(nonce: nonce)

            await output?.socialLoginProcessing(true)
            let hasBackup = await hasBackup()
            await output?.socialLoginProcessing(false)

            let input = MobileSocialWalletInput(credentials: credentials, hasBackup: hasBackup)
            await output?.socialLoginCompleted(input: input)

        } catch {
            switch error {
            case SocialAuthError.cancelled:
                break
            default:
                AppLogger.error("Social login failed", error: error)
                guard !Task.isCancelled else { return }
                await output?.socialLoginProcessing(false)
                await output?.socialLoginFailed(failure: .somethingWentWrong)
            }
        }

        await output?.socialLoginLoading(false)
    }
}

// MARK: - Private methods

private extension MobileSocialLoginHelper {
    func hasBackup() async -> Bool {
        do {
            return try await backupManager.hasBackup()
        } catch {
            AppLogger.error("Social login backup check failed", error: error)
            return false
        }
    }
}

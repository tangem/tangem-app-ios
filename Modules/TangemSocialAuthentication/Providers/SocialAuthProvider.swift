//
//  SocialAuthProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

public protocol SocialAuthProvider {
    /// Fetches a one-time nonce challenge for the wallet recovery flow.
    ///
    /// `POST api/authentication/v1/mobile/nonce/recover`
    func recoverNonce() async throws -> String

    /// Returns the wallet binding of the provider identity, or `nil` when the identity has none.
    func existingWalletBinding(credentials: SocialAuthCredentials) async throws(SocialAuthAPIError) -> SocialAuthWalletBinding?

    /// Encrypts the social backup recovery key `K` for deposit with the wallet registration.
    func encryptRecoveryKey(_ recoveryKey: Data) async throws -> String

    /// Recovers the wallet's secret payload from the social backup.
    func recoverWalletBackup(binding: SocialAuthWalletBinding) async throws -> SocialAuthRecoveredBackup
}

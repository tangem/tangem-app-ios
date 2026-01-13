//
//  UserWalletBiometricsUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import LocalAuthentication
import TangemLocalization
import TangemPay
import TangemSdk
import TangemVisa

class UserWalletBiometricsUnlocker: UserWalletBiometricsProvider {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository
    @Injected(\.tangemPayAuthorizationTokensRepository)
    private var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    func unlock() async throws -> LAContext {
        do {
            let context = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
            visaRefreshTokenRepository.fetch(using: context)
            tangemPayAuthorizationTokensRepository.fetch(using: context)
            return context
        } catch {
            Self.trackBiometricFailure(error: error)
            throw error
        }
    }

    private static func trackBiometricFailure(error: TangemSdkError) {
        var params: [Analytics.ParameterKey: Analytics.ParameterValue] = [
            .source: .signIn,
        ]

        let reason: Analytics.ParameterValue?
        switch error {
        case .userCancelled:
            reason = .biometricsReasonAuthenticationCanceled
        case .underlying(let underlyingError) where (underlyingError as? LAError)?.code == LAError.biometryLockout:
            reason = .biometricsReasonAuthenticationLockout
        default:
            reason = nil
        }

        params[.reason] = reason

        Analytics.log(.biometryFailed, params: params)
    }
}

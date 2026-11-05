//
//  CommonUserWalletLinker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import TangemSdk
import TangemFoundation
import TangemMobileWalletSdk
import TangemBackendAuthentication

final class CommonUserWalletLinker: UserWalletLinker {
    func isLinkSupported(_ userWalletModel: some UserWalletModel) -> Bool {
        guard userWalletModel.config.hasFeature(.nfcInteraction) else {
            return true
        }

        let unsupportedProducts: [Analytics.ProductType] = [.twin, .visa]

        return !unsupportedProducts.contains(userWalletModel.config.productType)
            && userWalletModel.keysRepository.keys.first?.curve == .secp256k1
    }

    nonisolated(nonsending) func link(_ userWalletModel: some UserWalletModel) async throws(UserWalletLinkError) {
        guard isLinkSupported(userWalletModel) else {
            BackendAuthLogger.debug("Skipped linking user wallet, not supported")
            throw .notSupported
        }

        do throws(UserWalletLinkError) {
            if userWalletModel.config.hasFeature(.nfcInteraction) {
                try await linkCard(userWalletModel)
            } else {
                try await linkMobile(userWalletModel)
            }

            BackendAuthLogger.info("Linked user wallet")
        } catch .failed(let underlying) {
            BackendAuthLogger.error("Failed to link user wallet", error: underlying)
            throw .failed(underlying: underlying)
        }
    }
}

// MARK: - Card

private extension CommonUserWalletLinker {
    nonisolated(nonsending) func linkCard(_ userWalletModel: some UserWalletModel) async throws(UserWalletLinkError) {
        guard let nonce = try await obtainNonce(id: userWalletModel.userWalletId) else {
            return
        }

        try checkCancellation()

        guard let request = try await attest(userWalletModel, nonce: nonce) else {
            return
        }

        try checkCancellation()

        do {
            try await BackendAuthenticationAssembly.submitUserWalletRegistration(request: request)
        } catch {
            throw .failed(underlying: error)
        }
    }

    func obtainNonce(id: UserWalletId) async throws(UserWalletLinkError) -> UserWalletRegistrationNonce? {
        do throws(ObtainUserWalletRegistrationNonceError) {
            return try await BackendAuthenticationAssembly.obtainUserWalletRegistrationNonce(id: id)
        } catch {
            if case .clientFailure(.requestNonceTimeout) = error {
                CommonBackendAuthenticationNonceAnalyticsReporter().reportColdUserWalletNonceTimeout()
            }

            throw .failed(underlying: error)
        }
    }

    nonisolated(nonsending) func attest(
        _ userWalletModel: some UserWalletModel,
        nonce: UserWalletRegistrationNonce
    ) async throws(UserWalletLinkError) -> UserWalletRegistrationRequest? {
        let task = CardUserWalletLinkTask(nonce: nonce)
        let tangemSdk = userWalletModel.config.makeTangemSdk()

        do throws(TangemSdkError) {
            return try await tangemSdk.startSession(with: task, filter: userWalletModel.config.cardSessionFilter)
        } catch .userCancelled {
            throw .cancelled
        } catch {
            throw .failed(underlying: error)
        }
    }
}

// MARK: - Mobile

private extension CommonUserWalletLinker {
    nonisolated(nonsending) func linkMobile(_ userWalletModel: some UserWalletModel) async throws(UserWalletLinkError) {
        let id = userWalletModel.userWalletId
        let isAlreadyRegistered = await BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus(id: id)

        guard !isAlreadyRegistered else {
            return
        }

        try checkCancellation()

        let secp256k1PublicKey: Data
        let context: MobileWalletContext

        do {
            secp256k1PublicKey = try userWalletModel.keysRepository.masterKeyPublicKey(curve: .secp256k1)
            context = try await MobileAuthUtil(
                userWalletId: id,
                config: userWalletModel.config,
                biometricsProvider: CommonUserWalletBiometricsProvider()
            )
            .unlockedContext()
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .failed(underlying: error)
        }

        try checkCancellation()

        do {
            try await BackendAuthenticationRegistrar.registerMobileWallet(
                id: id,
                context: context,
                secp256k1PublicKey: secp256k1PublicKey,
                mobileWalletSDK: CommonMobileWalletSdk()
            )
        } catch {
            throw .failed(underlying: error)
        }
    }
}

// MARK: - Cancellation

private extension CommonUserWalletLinker {
    func checkCancellation() throws(UserWalletLinkError) {
        guard !Task.isCancelled else {
            throw .cancelled
        }
    }
}

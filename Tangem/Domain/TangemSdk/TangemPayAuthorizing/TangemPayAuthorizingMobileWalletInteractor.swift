//
//  TangemPayAuthorizingMobileWalletInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk
import BlockchainSdk
import TangemMobileWalletSdk
import TangemVisa
import TangemLocalization

class TangemPayAuthorizingMobileWalletInteractor {
    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig
    private let mobileWalletSdk = CommonMobileWalletSdk()

    init(userWalletId: UserWalletId, userWalletConfig: UserWalletConfig,) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
    }
}

// MARK: - TangemPayAuthorizing

extension TangemPayAuthorizingMobileWalletInteractor: TangemPayAuthorizing {
    var syncNeededTitle: String {
        Localization.tangempaySyncNeededRestoreAccess
    }

    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws -> TangemPayAuthorizingResponse {
        let context = try await unlock()
        let mobileWallet = try mobileWalletSdk.deriveMasterKeys(context: context)

        guard let seedKey = mobileWallet.wallets.first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })?.publicKey else {
            throw TangemSdkError.walletNotFound
        }

        let derivationPath = TangemPayUtilities.derivationPath
        let rawResult = try mobileWalletSdk.deriveKeys(context: context, derivationPaths: [seedKey: [derivationPath]])
        let derivationResult: DerivationResult = rawResult.reduce(into: [:]) { partialResult, keyInfo in
            partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
        }

        guard let extendedPublicKey = derivationResult[seedKey]?[derivationPath] else {
            throw Error.derivedKeyNotFound
        }

        let walletPublicKey = Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .plain(
                .init(
                    path: derivationPath,
                    extendedPublicKey: extendedPublicKey
                )
            )
        )

        let customerWalletAddress = try TangemPayUtilities.makeAddress(using: walletPublicKey)
        let tokens = try await handleCustomerWalletAuthorization(
            context: context,
            walletPublicKey: walletPublicKey,
            customerWalletId: customerWalletId,
            customerWalletAddress: customerWalletAddress,
            authorizationService: authorizationService
        )

        return TangemPayAuthorizingResponse(
            customerWalletAddress: customerWalletAddress,
            tokens: tokens,
            derivationResult: derivationResult
        )
    }

    private func handleCustomerWalletAuthorization(
        context: MobileWalletContext,
        walletPublicKey: Wallet.PublicKey,
        customerWalletId: String,
        customerWalletAddress: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws -> TangemPayAuthorizationTokens {
        VisaLogger.info("Requesting challenge for wallet authorization")

        let challengeResponse = try await authorizationService.getChallenge(
            customerWalletAddress: customerWalletAddress,
            customerWalletId: customerWalletId
        )

        VisaLogger.info("Received challenge to sign")

        let signRequest = try TangemPayUtilities.prepareForSign(challengeResponse: challengeResponse)

        let dataToSign = SignData(
            derivationPath: walletPublicKey.derivationPath,
            hashes: [signRequest.hash],
            publicKey: walletPublicKey.blockchainKey
        )

        let signResponse = try mobileWalletSdk.sign(
            dataToSign: [dataToSign],
            seedKey: walletPublicKey.seedKey,
            context: context
        )

        guard let signature = signResponse[dataToSign.publicKey]?.first else {
            throw Error.signatureNotFound
        }

        VisaLogger.info("Challenge signed with customer wallet public key")

        let unmarshalledSignature = try Secp256k1Signature(with: signature).unmarshal(
            with: walletPublicKey.blockchainKey,
            hash: signRequest.hash
        )

        let authorizationTokensResponse = try await authorizationService.getTokens(
            sessionId: challengeResponse.sessionId,
            signedChallenge: unmarshalledSignature.data.hexString,
            messageFormat: signRequest.message
        )

        VisaLogger.info("Receive authorization tokens response")

        return authorizationTokensResponse
    }
}

private extension TangemPayAuthorizingMobileWalletInteractor {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletId,
            config: userWalletConfig,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )

        let unlockResult = try await authUtil.unlock()
        return try await handleUnlockResult(unlockResult, userWalletId: userWalletId)
    }

    func handleUnlockResult(
        _ result: MobileAuthUtil.Result,
        userWalletId: UserWalletId
    ) async throws -> MobileWalletContext {
        switch result {
        case .successful(let context):
            return context
        case .canceled, .userWalletNeedsToDelete:
            throw CancellationError()
        }
    }
}

extension TangemPayAuthorizingMobileWalletInteractor {
    enum Error: Swift.Error {
        case derivedKeyNotFound
        case signatureNotFound
    }
}

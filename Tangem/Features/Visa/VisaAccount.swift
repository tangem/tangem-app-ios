//
//  VisaAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemSdk

final class VisaAccount {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    private let walletModel: any WalletModel
    private let authorizationTokensHandler: VisaAuthorizationTokensHandler

    private var visaRefreshTokenId: VisaRefreshTokenId {
        .customerWalletAddress(customerWalletAddress)
    }

    private var customerWalletAddress: String {
        walletModel.defaultAddressString
    }

    init(walletModel: any WalletModel) {
        assert(walletModel.tokenItem.blockchain == VisaUtilities.visaBlockchain)
        self.walletModel = walletModel

        authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(
                customerWalletAddress: walletModel.defaultAddressString,
                authorizationTokens: nil,
                refreshTokenSaver: nil
            )

        // No reference cycle here, self is stored as weak in VisaAuthorizationTokensHandler
        authorizationTokensHandler.setupRefreshTokenSaver(self)
    }

    #if ALPHA || BETA || DEBUG
    func launchKYC() async throws {
        try await prepareTokensHandler()

        let customerInfoManagementService = VisaCustomerCardInfoProviderBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken
        )
    }
    #endif // ALPHA || BETA || DEBUG

    private func prepareTokensHandler() async throws {
        if await authorizationTokensHandler.accessToken == nil {
            let tokens = try await getTokens()
            try await authorizationTokensHandler.setupTokens(tokens)
        }

        if await authorizationTokensHandler.refreshTokenExpired {
            let tokens = try await authorizeWithCustomerWallet()
            try await authorizationTokensHandler.setupTokens(tokens)
        }

        if await authorizationTokensHandler.accessTokenExpired {
            try await authorizationTokensHandler.forceRefreshToken()
        }
    }

    private func getTokens() async throws -> VisaAuthorizationTokens {
        if let savedRefreshToken = visaRefreshTokenRepository.getToken(forVisaRefreshTokenId: visaRefreshTokenId) {
            return VisaAuthorizationTokens(
                accessToken: nil,
                refreshToken: savedRefreshToken,
                authorizationType: .customerWallet
            )
        }

        return try await authorizeWithCustomerWallet()
    }

    private func authorizeWithCustomerWallet() async throws -> VisaAuthorizationTokens {
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()

        let task = CustomerWalletAuthorizationTask(
            walletPublicKey: walletModel.publicKey,
            walletAddress: customerWalletAddress,
            authorizationService: VisaAPIServiceBuilder().buildAuthorizationService()
        )

        let tokens = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(with: task) { result in
                switch result {
                case .success(let hashResponse):
                    continuation.resume(returning: hashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        return tokens
    }
}

extension VisaAccount: VisaRefreshTokenSaver {
    func saveRefreshTokenToStorage(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws {
        try visaRefreshTokenRepository.save(refreshToken: refreshToken, visaRefreshTokenId: visaRefreshTokenId)
    }
}

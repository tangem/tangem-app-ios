//
//  VisaAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemSdk
import TangemFoundation

final class VisaAccount: ObservableObject {
    var customerInfoPublisher: AnyPublisher<VisaCustomerInfoResponse, Never> {
        customerInfoSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let authorizer: TangemPayAuthorizer
    private let customerInfoManagementService: any CustomerInfoManagementService

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)
    private var customerInfoPollingTask: Task<Void, Never>?

    private var walletModel: any WalletModel {
        authorizer.walletModel
    }

    init(authorizer: TangemPayAuthorizer, tokens: VisaAuthorizationTokens) {
        self.authorizer = authorizer

        authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(
                customerWalletAddress: authorizer.walletModel.defaultAddressString,
                authorizationTokens: tokens,
                refreshTokenSaver: nil
            )

        customerInfoManagementService = VisaCustomerCardInfoProviderBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        // No reference cycle here, self is stored as weak in VisaAuthorizationTokensHandler
        authorizationTokensHandler.setupRefreshTokenSaver(self)

        startCustomerInfoPolling()
    }

    convenience init?(walletModel: any WalletModel) {
        guard walletModel.tokenItem.blockchain == VisaUtilities.visaBlockchain else {
            return nil
        }

        @Injected(\.visaRefreshTokenRepository) var visaRefreshTokenRepository: VisaRefreshTokenRepository
        let visaRefreshTokenId = VisaRefreshTokenId.customerWalletAddress(walletModel.defaultAddressString)

        // If there was no refreshToken saved - means user never got tangem pay offer
        guard let refreshToken = visaRefreshTokenRepository.getToken(forVisaRefreshTokenId: visaRefreshTokenId) else {
            return nil
        }

        let authorizer = TangemPayAuthorizer(walletModel: walletModel)

        let tokens = VisaAuthorizationTokens(
            accessToken: nil,
            refreshToken: refreshToken,
            authorizationType: .customerWallet
        )

        self.init(authorizer: authorizer, tokens: tokens)
    }

    convenience init?(userWalletModel: UserWalletModel) {
        guard let walletModel = userWalletModel.visaWalletModel else {
            return nil
        }

        self.init(walletModel: walletModel)
    }

    #if ALPHA || BETA || DEBUG
    func launchKYC() async throws {
        try await prepareTokensHandler()

        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken
        )
    }
    #endif // ALPHA || BETA || DEBUG

    private func prepareTokensHandler() async throws {
        if await authorizationTokensHandler.refreshTokenExpired {
            let tokens = try await authorizer.authorizeWithCustomerWallet()
            try await authorizationTokensHandler.setupTokens(tokens)
        }

        if await authorizationTokensHandler.accessTokenExpired {
            try await authorizationTokensHandler.forceRefreshToken()
        }
    }

    private func startCustomerInfoPolling() {
        customerInfoPollingTask?.cancel()

        let polling = PollingSequence(
            interval: .minute,
            request: { [weak self] () -> VisaCustomerInfoResponse? in
                guard let self else { return nil }
                try await prepareTokensHandler()
                return try await customerInfoManagementService.loadCustomerInfo()
            }
        )

        customerInfoPollingTask = Task { [weak self] in
            for await result in polling {
                switch result {
                case .success(let customerInfo):
                    self?.customerInfoSubject.send(customerInfo)
                case .failure(let error):
                    // [REDACTED_TODO_COMMENT]
                    print("TAG:", error.localizedDescription)
                }
            }
        }
    }

    deinit {
        customerInfoPollingTask?.cancel()
    }
}

extension VisaAccount: VisaRefreshTokenSaver {
    func saveRefreshTokenToStorage(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws {
        try visaRefreshTokenRepository.save(refreshToken: refreshToken, visaRefreshTokenId: visaRefreshTokenId)
    }
}

final class TangemPayAuthorizer {
    let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func authorizeWithCustomerWallet() async throws -> VisaAuthorizationTokens {
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()

        let task = CustomerWalletAuthorizationTask(
            walletPublicKey: walletModel.publicKey,
            walletAddress: walletModel.defaultAddressString,
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

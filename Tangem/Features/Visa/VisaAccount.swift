//
//  VisaAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemSdk

struct VisaAccount {
    private let walletModel: any WalletModel
    private let biometricsStorage = BiometricsStorage()

    private var storageKey: String {
        StorageKey.visaCustomerWalletAuthToken.rawValue
    }

    init(walletModel: any WalletModel) {
        assert(walletModel.tokenItem.blockchain == VisaUtilities.visaBlockchain)
        self.walletModel = walletModel
    }

    #if ALPHA || BETA || DEBUG
    func launchKYC() async throws {
        let tokens = try await getTokens()

        let authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(visaAuthorizationTokens: tokens)

        let customerInfoManagementService = VisaCustomerCardInfoProviderBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        try await KYCService.start(getToken: customerInfoManagementService.loadKYCAccessToken)
    }
    #endif // ALPHA || BETA || DEBUG

    private func getTokens() async throws -> VisaAuthorizationTokens {
        if let savedTokens = try await readSavedAuthTokens() {
            return savedTokens
        }

        let tokens = try await authorizeWithCustomerWallet()

        if let data = try? JSONEncoder().encode(tokens) {
            try biometricsStorage.store(data, forKey: storageKey)
        }

        return tokens
    }

    private func readSavedAuthTokens() async throws -> VisaAuthorizationTokens? {
        let context = try await UserWalletBiometricsUnlocker().unlock()

        guard let data = try biometricsStorage.get(storageKey, context: context),
              let decoded = try? JSONDecoder().decode(VisaAuthorizationTokens.self, from: data)
        else {
            return nil
        }

        return decoded
    }

    private func authorizeWithCustomerWallet() async throws -> VisaAuthorizationTokens {
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

extension VisaAccount {
    enum StorageKey: String {
        case visaCustomerWalletAuthToken
    }
}

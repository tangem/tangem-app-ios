//
//  TangemPayOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemFoundation

final class TangemPayOfferViewModel: ObservableObject {
    @Published private(set) var isLoading = false

    private let userWalletModel: any UserWalletModel
    private let closeOfferScreen: () -> Void

    init(
        userWalletModel: any UserWalletModel,
        closeOfferScreen: @escaping () -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.closeOfferScreen = closeOfferScreen
    }

    func getCard() {
        #if ALPHA || BETA || DEBUG
        isLoading = true
        runTask(in: self) { viewModel in
            do {
                let tangemPayAccount = try await viewModel.makeTangemPayAccount()
                let tangemPayStatus = try await tangemPayAccount.getTangemPayStatus()

                // [REDACTED_TODO_COMMENT]
                // [REDACTED_INFO]

                switch tangemPayStatus {
                case .kycRequired:
                    try await tangemPayAccount.launchKYC {
                        viewModel.closeOfferScreen()
                    }
                default:
                    viewModel.closeOfferScreen()
                }
            } catch {
                viewModel.closeOfferScreen()
            }
        }
        #endif // ALPHA || BETA || DEBUG
    }

    private func makeTangemPayAccount() async throws -> TangemPayAccount {
        let tangemPayAuthorizer = try await makeTangemPayAuthorizer()
        let tokens = try await tangemPayAuthorizer.authorizeWithCustomerWallet()
        return TangemPayAccount(authorizer: tangemPayAuthorizer, tokens: tokens)
    }

    private func makeTangemPayAuthorizer() async throws -> TangemPayAuthorizer {
        if let walletModel = userWalletModel.visaWalletModel {
            return TangemPayAuthorizer(walletModel: walletModel)
        }

        let visaBlockchainNetwork = BlockchainNetwork(
            VisaUtilities.visaBlockchain,
            derivationPath: VisaUtilities.visaDefaultDerivationPath
        )
        _ = try await userWalletModel.userTokensManager.add(.blockchain(visaBlockchainNetwork))

        if let walletModel = userWalletModel.visaWalletModel {
            return TangemPayAuthorizer(walletModel: walletModel)
        }

        throw TangemPayOfferError.unableToCreateRequiredWalletModel
    }
}

private extension TangemPayOfferViewModel {
    enum TangemPayOfferError: Error {
        case unableToCreateRequiredWalletModel
    }
}

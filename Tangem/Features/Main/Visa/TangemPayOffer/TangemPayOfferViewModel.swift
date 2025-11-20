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
import TangemSdk

final class TangemPayOfferViewModel: ObservableObject {
    @Published private(set) var isLoading = false

    private let userWalletModel: any UserWalletModel
    private let closeOfferScreen: @MainActor () -> Void

    init(
        userWalletModel: any UserWalletModel,
        closeOfferScreen: @escaping @MainActor () -> Void
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
                viewModel.userWalletModel.update(type: .tangemPayOfferAccepted(tangemPayAccount))

                switch tangemPayStatus {
                case .kycRequired:
                    try await tangemPayAccount.launchKYC {
                        tangemPayAccount.loadCustomerInfo()
                        runTask(in: viewModel) { viewModel in
                            await viewModel.closeOfferScreen()
                        }
                    }
                default:
                    await viewModel.closeOfferScreen()
                }
            } catch {
                await viewModel.closeOfferScreen()
            }
        }
        #endif // ALPHA || BETA || DEBUG
    }

    private func makeTangemPayAccount() async throws -> TangemPayAccount {
        let tangemPayAuthorizer = TangemPayAuthorizer(
            interactor: userWalletModel.tangemPayAuthorizingInteractor,
            keysRepository: userWalletModel.keysRepository
        )
        let tokens = try await tangemPayAuthorizer.authorizeWithCustomerWallet()

        guard let walletPublicKey = TangemPayUtilities.getKey(from: userWalletModel.keysRepository) else {
            throw TangemPayOfferError.unableToCreateWalletPublicKey
        }

        let walletAddress = try TangemPayUtilities.makeAddress(using: walletPublicKey)

        return TangemPayAccount(
            authorizer: tangemPayAuthorizer,
            walletAddress: walletAddress,
            tokens: tokens
        )
    }
}

private extension TangemPayOfferViewModel {
    enum TangemPayOfferError: Error {
        case unableToCreateWalletPublicKey
    }
}

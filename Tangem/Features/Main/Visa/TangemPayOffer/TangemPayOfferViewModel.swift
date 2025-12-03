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
    @Published var termsFeesAndLimitsViewModel: WebViewContainerViewModel?

    private let tangemPayAccountManager: TangemPayAccountManaging
    private let closeOfferScreen: @MainActor () -> Void

    init(
        tangemPayAccountManager: TangemPayAccountManaging,
        closeOfferScreen: @escaping @MainActor () -> Void
    ) {
        self.tangemPayAccountManager = tangemPayAccountManager
        self.closeOfferScreen = closeOfferScreen
    }

    func getCard() {
        isLoading = true
        runTask(in: self) { viewModel in
            do {
                try await viewModel.tangemPayAccountManager.onTangemPayOfferAccepted {
                    runTask(in: viewModel) { viewModel in
                        await viewModel.closeOfferScreen()
                    }
                }
            } catch {
                await viewModel.closeOfferScreen()
            }
        }
    }

    func termsFeesAndLimits() {
        termsFeesAndLimitsViewModel = .init(
            url: AppConstants.tangemPayTermsAndLimitsURL,
            title: "",
            withCloseButton: true
        )
    }
}

private extension TangemPayOfferViewModel {
    enum TangemPayOfferError: Error {
        case unableToCreateWalletPublicKey
    }
}

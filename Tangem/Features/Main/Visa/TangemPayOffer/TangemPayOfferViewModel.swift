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
    @Published var walletSelectorViewModel: TangemPayWalletSelectorViewModel?

    private weak var coordinator: TangemPayOnboardingRoutable?
    private let closeOfferScreen: @MainActor () -> Void

    init(
        closeOfferScreen: @escaping @MainActor () -> Void,
        coordinator: TangemPayOnboardingRoutable?
    ) {
        self.coordinator = coordinator
        self.closeOfferScreen = closeOfferScreen
    }

    func onAppear() {
        Analytics.log(.visaOnboardingVisaActivationScreenOpened)
    }

    func getCard() {
        Analytics.log(.visaOnboardingButtonVisaGetCard)

        coordinator?.openWalletSelector { [weak self] walletModel in
            self?.acceptOffer(on: walletModel)
        }
    }

    func acceptOffer(on userWalletModel: UserWalletModel) {
        isLoading = true
        runTask(in: self) { viewModel in
            do {
                let tangemPayManager = userWalletModel.tangemPayManager
                try await tangemPayManager.authorizeWithCustomerWallet()

                switch tangemPayManager.state {
                case .kyc:
                    try await tangemPayManager.launchKYC {
                        runTask(in: viewModel) { viewModel in
                            await tangemPayManager.refreshState()
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
    }

    func termsFeesAndLimits() {
        Analytics.log(.visaOnboardingButtonVisaViewTerms)

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

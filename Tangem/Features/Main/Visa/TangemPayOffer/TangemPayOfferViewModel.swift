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
import TangemUI

final class TangemPayOfferViewModel: ObservableObject {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Published private(set) var isLoading = false
    @Published var termsFeesAndLimitsViewModel: WebViewContainerViewModel?

    var getCardButtonIcon: MainButton.Icon? {
        if let model = userWalletRepository.models.first, userWalletRepository.models.count == 1 {
            return CommonTangemIconProvider(config: model.config).getMainButtonIcon()
        }

        return nil
    }

    private weak var coordinator: TangemPayOnboardingRoutable?
    private let closeOfferScreen: @MainActor () -> Void
    private let walletSelectionType: TangemPayWalletSelectionType

    init(
        walletSelectionType: TangemPayWalletSelectionType,
        closeOfferScreen: @escaping @MainActor () -> Void,
        coordinator: TangemPayOnboardingRoutable?
    ) {
        self.walletSelectionType = walletSelectionType
        self.coordinator = coordinator
        self.closeOfferScreen = closeOfferScreen
    }

    func onAppear() {
        Analytics.log(.visaOnboardingVisaActivationScreenOpened)
    }

    func getCard() {
        Analytics.log(.visaOnboardingButtonVisaGetCard)

        switch walletSelectionType {
        case .single(let walletModel):
            acceptOffer(on: walletModel)

        case .multiple(let walletModels):
            coordinator?.openWalletSelector(
                from: walletModels
            ) { [weak self] selectedModel in
                self?.acceptOffer(on: selectedModel)
            }
        }
    }

    func acceptOffer(on userWalletModel: UserWalletModel) {
        isLoading = true
        runTask(in: self) { viewModel in
            do {
                let tangemPayManager = userWalletModel.tangemPayManager
                await tangemPayManager.authorizeWithCustomerWallet(authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor)

                switch tangemPayManager.state {
                case .kycRequired:
                    try await tangemPayManager.launchKYC {
                        await viewModel.closeOfferScreen()
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

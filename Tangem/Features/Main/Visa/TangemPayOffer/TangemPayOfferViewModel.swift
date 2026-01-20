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
    @Injected(\.tangemPayAvailabilityRepository)
    private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

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

        if tangemPayAvailabilityRepository.availableUserWalletModels.count == 1,
           let userWalletModel = tangemPayAvailabilityRepository.availableUserWalletModels.first {
            acceptOffer(on: userWalletModel)
        } else {
            coordinator?.openWalletSelector { [weak self] walletModel in
                self?.acceptOffer(on: walletModel)
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

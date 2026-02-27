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
        case .single(let id):
            guard
                let userWalletModel = userWalletRepository.models.first(
                    where: { $0.userWalletId.stringValue == id }
                )
            else {
                VisaLogger.info("UserWalletModel not found for given id. This is unexpected.")
                Task { @MainActor in
                    closeOfferScreen()
                }
                return
            }

            acceptOffer(on: userWalletModel)

        case .multiple(let ids):
            let walletModels = userWalletRepository.models
                .filter { ids.contains($0.userWalletId.stringValue) }

            guard walletModels.isNotEmpty else {
                VisaLogger.info("UserWalletModel not found for given ids. This is unexpected.")
                Task { @MainActor in
                    closeOfferScreen()
                }
                return
            }

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
            await userWalletModel.accountModelsManager.acceptTangemPayOffer(
                authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor
            )
            await viewModel.closeOfferScreen()
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

//
//  PriceAlertsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI

final class PriceAlertsViewModel: ObservableObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published private(set) var viewState: ViewState?

    private let tokenId: PriceAlertTokenId

    init(tokenId: PriceAlertTokenId) {
        self.tokenId = tokenId
        viewState = makeInitialViewState()
    }

    func onCloseTapAction() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Private

private extension PriceAlertsViewModel {
    /// Onboarding is shown once per device; afterwards the sheet opens straight on the wallet selector.
    func makeInitialViewState() -> ViewState {
        if AppSettings.shared.isPriceAlertsOnboardingShown {
            return .walletSelector(viewModel: makeWalletSelectorViewModel())
        }

        return .onboarding(viewModel: makeOnboardingViewModel())
    }

    func makeOnboardingViewModel() -> PriceAlertsOnboardingViewModel {
        PriceAlertsOnboardingViewModel { [weak self] in
            self?.handleOnboardingFinished()
        }
    }

    func makeWalletSelectorViewModel() -> PriceAlertsWalletSelectorViewModel {
        PriceAlertsWalletSelectorViewModel(tokenId: tokenId) { [weak self] in
            self?.onCloseTapAction()
        }
    }

    func handleOnboardingFinished() {
        AppSettings.shared.isPriceAlertsOnboardingShown = true
        viewState = .walletSelector(viewModel: makeWalletSelectorViewModel())
    }
}

// MARK: - FloatingSheetContentViewModel

extension PriceAlertsViewModel: FloatingSheetContentViewModel {}

// MARK: - ViewState

extension PriceAlertsViewModel {
    enum ViewState: Identifiable, Equatable {
        case onboarding(viewModel: PriceAlertsOnboardingViewModel)
        case walletSelector(viewModel: PriceAlertsWalletSelectorViewModel)

        var id: String {
            switch self {
            case .onboarding: "onboarding"
            case .walletSelector: "walletSelector"
            }
        }

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            lhs.id == rhs.id
        }
    }
}

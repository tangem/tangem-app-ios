//
//  TangemPayVerifiedViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUI
import struct TangemUIUtils.AlertBinder

final class TangemPayVerifiedViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var state: State = .loading
    @Published private(set) var isStartingOnboarding = false
    @Published var alert: AlertBinder?

    private let interactor: any TangemPayUnifiedOnboardingInteractor
    private let addressSigner: TangemPayBankingAccountAddressSigning
    private let signingType: SigningActionButtonViewType
    private weak var coordinator: TangemPayVerifiedRoutable?

    init(
        interactor: any TangemPayUnifiedOnboardingInteractor,
        addressSigner: TangemPayBankingAccountAddressSigning,
        signingType: SigningActionButtonViewType,
        coordinator: TangemPayVerifiedRoutable?
    ) {
        self.interactor = interactor
        self.addressSigner = addressSigner
        self.signingType = signingType
        self.coordinator = coordinator
    }

    var description: String? {
        guard case .loaded(let products) = state else {
            return nil
        }

        switch (products.isCardAvailable, products.isAccountAvailable) {
        case (true, true): return Localization.tangempayVerifiedDescriptionAll
        case (true, false): return Localization.tangempayVerifiedDescriptionPaymentAccount
        case (false, true): return Localization.tangempayVerifiedDescriptionMoneyAccount
        case (false, false): return Localization.tangempayVerifiedDescriptionNone
        }
    }

    var primaryActionTitle: String {
        guard case .loaded(let products) = state else {
            return Localization.commonClose
        }

        if products.isCardAvailable {
            return Localization.tangempayVerifiedChoosePlan
        }
        if products.isAccountAvailable {
            return Localization.tangempayVerifiedOpenMoneyAccount
        }
        return Localization.commonClose
    }

    var primaryActionSigningType: SigningActionButtonViewType? {
        guard case .loaded(let products) = state, !products.isCardAvailable, products.isAccountAvailable else {
            return nil
        }
        return signingType
    }

    @MainActor
    func loadProductsAvailabilityIfNeeded() async {
        guard case .loading = state else {
            return
        }

        await loadProductsAvailability()
    }

    @MainActor
    func loadProductsAvailability() async {
        state = .loading
        do {
            let products = try await interactor.loadProductsAvailability()
            state = .loaded(products)
        } catch {
            guard !Task.isCancelled else {
                return
            }

            alertPresenter.present(alert: makeRetryAlert())
        }
    }

    func primaryAction() {
        guard case .loaded(let products) = state, !isStartingOnboarding else {
            return
        }

        if products.isCardAvailable {
            coordinator?.openSelectPlan(products: products)
        } else if products.isAccountAvailable {
            placeAccountOnlyOrder(products: products)
        } else {
            interactor.hideAccountFromHome()
            coordinator?.closeVerifiedFlow()
        }
    }

    func close() {
        coordinator?.closeVerifiedFlow()
    }
}

// MARK: - Private

private extension TangemPayVerifiedViewModel {
    func placeAccountOnlyOrder(products: TangemPayProductsAvailability) {
        isStartingOnboarding = true

        runTask(in: self) { @MainActor viewModel in
            do throws(TangemPayOnboardingOrderError) {
                try await viewModel.interactor.placeOnboardingOrder(products: products, plan: nil, addressSigner: viewModel.addressSigner)
                viewModel.coordinator?.onboardingOrderDidPlace()
            } catch {
                viewModel.isStartingOnboarding = false
                viewModel.handle(error)
            }
        }
    }

    @MainActor
    func handle(_ error: TangemPayOnboardingOrderError) {
        switch error {
        case .cancelled:
            break
        case .alreadyOnboarded:
            coordinator?.closeVerifiedFlow()
        case .notEligible:
            runTask(in: self) { await $0.loadProductsAvailability() }
        case .failed:
            alert = AlertBinder(title: Localization.commonError, message: Localization.commonUnknownError)
        }
    }

    func makeRetryAlert() -> AlertBinder {
        AlertBinder(
            alert: .init(
                title: Text(Localization.commonSomethingWentWrong),
                message: Text(Localization.commonTryAgainLater),
                primaryButton: .default(Text(Localization.commonRetry)) { [weak self] in
                    guard let self else { return }
                    runTask(in: self) { await $0.loadProductsAvailability() }
                },
                secondaryButton: .cancel(Text(Localization.commonCancel)) { [weak self] in
                    self?.close()
                }
            )
        )
    }
}

// MARK: - Types

extension TangemPayVerifiedViewModel {
    enum State {
        case loading
        case loaded(TangemPayProductsAvailability)
    }
}

// MARK: - Routable

protocol TangemPayVerifiedRoutable: AnyObject {
    func openSelectPlan(products: TangemPayProductsAvailability)
    func onboardingOrderDidPlace()
    func closeVerifiedFlow()
}

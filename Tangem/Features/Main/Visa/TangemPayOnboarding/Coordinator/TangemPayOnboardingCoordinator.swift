//
//  TangemPayOnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUI

protocol TangemPayOnboardingRoutable: AnyObject {
    func openWalletSelector(
        from: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    )
    func openResidency(onAvailable: @escaping () -> Void)
}

final class TangemPayOnboardingCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: TangemPayOnboardingViewModel?
    @Published var residencyCoordinator: TangemPayResidencyCoordinator?

    private lazy var geoStore = TangemPayGeoStore(
        repository: CommonTangemPayGeoRepository()
    )

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        prefetchCountriesIfNeeded()

        rootViewModel = .init(
            source: options.source,
            availableSelection: options.availableSelection,
            coordinator: self,
            closeOfferScreen: { [weak self] in
                self?.dismiss(with: ())
            }
        )
    }
}

extension TangemPayOnboardingCoordinator: TangemPayOnboardingRoutable {
    func openWalletSelector(
        from walletModels: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    ) {
        let _onSelect: (UserWalletModel) -> Void = { [weak self] walletModel in
            self?.dismissActiveSheet()
            onSelect(walletModel)
        }

        let walletSelectorViewModel = TangemPayWalletSelectorViewModel(
            userWalletModels: walletModels,
            onSelect: _onSelect
        ) { [weak self] in
            self?.dismissActiveSheet()
        }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: walletSelectorViewModel)
        }
    }

    func openResidency(onAvailable: @escaping () -> Void) {
        let dismissAction: Action<TangemPayResidencyCoordinator.DismissOptions?> = { [weak self] options in
            self?.residencyCoordinator = nil

            switch options {
            case .available:
                onAvailable()

            case .joinedWaitlist:
                self?.dismiss(with: ())
                Toast(view: SuccessToast(text: Localization.tangempayWaitlistJoinedMessage))
                    .present(layout: .top(padding: 12), type: .temporary())

            case .closed, .none:
                self?.dismiss(with: ())
            }
        }

        let coordinator = TangemPayResidencyCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(product: .paymentAccount, geoStore: geoStore))
        residencyCoordinator = coordinator
    }

    private func prefetchCountriesIfNeeded() {
        guard FeatureProvider.isAvailable(.tangemPayChooseCountry) else {
            return
        }

        geoStore.loadCountries()
    }

    private func dismissActiveSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension TangemPayOnboardingCoordinator {
    struct Options {
        let source: TangemPayOnboardingSource
        let availableSelection: TangemPayWalletSelectionType
    }

    typealias DismissOptions = Void
}

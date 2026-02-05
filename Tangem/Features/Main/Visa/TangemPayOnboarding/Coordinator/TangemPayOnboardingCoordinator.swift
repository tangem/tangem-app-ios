//
//  TangemPayOnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

protocol TangemPayOnboardingRoutable: AnyObject {
    func openWalletSelector(
        from: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    )
}

final class TangemPayOnboardingCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: TangemPayOnboardingViewModel?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(
            source: options.source,
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

    private func dismissActiveSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension TangemPayOnboardingCoordinator {
    struct Options {
        let source: TangemPayOnboardingSource
    }

    typealias DismissOptions = Void
}

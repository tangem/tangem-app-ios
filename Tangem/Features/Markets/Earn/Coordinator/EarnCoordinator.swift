//
//  EarnCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

final class EarnCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>
    let openEarnTokenDetailsAction: (_ token: EarnTokenModel, _ userWalletModels: [UserWalletModel]) -> Void

    // MARK: - Root ViewModels

    @Published var rootViewModel: EarnDetailViewModel?
    @Published var error: AlertBinder?

    // MARK: - Child ViewModels

    @Published var networkFilterBottomSheetViewModel: EarnNetworkFilterBottomSheetViewModel?
    @Published var typeFilterBottomSheetViewModel: EarnTypeFilterBottomSheetViewModel?

    // MARK: - Private Properties

    private let filterProvider = EarnDataFilterProvider()

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        openEarnTokenDetailsAction: @escaping (_ token: EarnTokenModel, _ userWalletModels: [UserWalletModel]) -> Void
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.openEarnTokenDetailsAction = openEarnTokenDetailsAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            let earnDataProvider = EarnDataProvider()

            rootViewModel = EarnDetailViewModel(
                dataProvider: earnDataProvider,
                filterProvider: filterProvider,
                mostlyUsedTokens: options.mostlyUsedTokens,
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension EarnCoordinator {
    struct Options {
        let mostlyUsedTokens: [EarnTokenModel]
    }
}

// MARK: - EarnDetailRoutable

extension EarnCoordinator: EarnDetailRoutable {
    func dismiss() {
        dismissAction(())
    }

    func openAddEarnToken(for token: EarnTokenModel, userWalletModels: [any UserWalletModel]) {
        openEarnTokenDetailsAction(token, userWalletModels)
    }

    func openNetworksFilter() {
        networkFilterBottomSheetViewModel = EarnNetworkFilterBottomSheetViewModel(
            filterProvider: filterProvider,
            onDismiss: { [weak self] in
                self?.networkFilterBottomSheetViewModel = nil
            }
        )
    }

    func openTypesFilter() {
        typeFilterBottomSheetViewModel = EarnTypeFilterBottomSheetViewModel(
            filterProvider: filterProvider,
            onDismiss: { [weak self] in
                self?.typeFilterBottomSheetViewModel = nil
            }
        )
    }
}

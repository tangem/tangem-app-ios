//
//  EarnCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

@MainActor
final class EarnCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published var rootViewModel: EarnDetailViewModel?
    @Published var error: AlertBinder?

    // MARK: - Child ViewModels

    @Published var networkFilterBottomSheetViewModel: EarnNetworkFilterBottomSheetViewModel?
    @Published var typeFilterBottomSheetViewModel: EarnTypeFilterBottomSheetViewModel?

    // MARK: - Private Properties

    private var filterProvider: EarnDataFilterProvider?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let filterProvider = EarnDataFilterProvider()
        self.filterProvider = filterProvider

        rootViewModel = EarnDetailViewModel(
            filterProvider: filterProvider,
            mostlyUsedTokens: options.mostlyUsedTokens,
            coordinator: self
        )
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

    func openEarnTokenDetails(for token: EarnTokenModel) {
        // Will be implemented in future iteration
    }

    func openNetworksFilter() {
        guard let filterProvider else { return }

        networkFilterBottomSheetViewModel = EarnNetworkFilterBottomSheetViewModel(
            filterProvider: filterProvider,
            onDismiss: { [weak self] in
                self?.networkFilterBottomSheetViewModel = nil
            }
        )
    }

    func openTypesFilter() {
        guard let filterProvider else { return }

        typeFilterBottomSheetViewModel = EarnTypeFilterBottomSheetViewModel(
            filterProvider: filterProvider,
            onDismiss: { [weak self] in
                self?.typeFilterBottomSheetViewModel = nil
            }
        )
    }
}

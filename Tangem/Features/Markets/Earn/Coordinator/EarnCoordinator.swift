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

    @Published var filterBottomSheetViewModel: EarnFilterBottomSheetViewModel?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = EarnDetailViewModel(
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
        guard let filterProvider = rootViewModel?.filterProvider else { return }

        filterBottomSheetViewModel = .init(kind: .networks, provider: filterProvider) { [weak self] in
            self?.filterBottomSheetViewModel = nil
        }
    }

    func openTypesFilter() {
        guard let filterProvider = rootViewModel?.filterProvider else { return }

        filterBottomSheetViewModel = .init(kind: .types, provider: filterProvider) { [weak self] in
            self?.filterBottomSheetViewModel = nil
        }
    }
}

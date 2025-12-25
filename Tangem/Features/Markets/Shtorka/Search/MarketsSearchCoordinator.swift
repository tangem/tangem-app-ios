//
//  MarketsSearchCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemStaking
import struct TangemUIUtils.AlertBinder

final class MarketsSearchCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published var rootViewModel: MarketsSearchViewModel? = nil
    @Published var error: AlertBinder? = nil

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var marketsSearchCoordinator: MarketsSearchCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let marketsViewModel = MarketsSearchViewModel(
            quotesRepositoryUpdateHelper: options.quotesRepositoryUpdateHelper,
            coordinator: self
        )

        rootViewModel = marketsViewModel
    }
}

extension MarketsSearchCoordinator {
    struct Options {
        let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    }
}

// MARK: - MarketsRoutable

extension MarketsSearchCoordinator: MarketsRoutable {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        marketsListOrderBottomSheetViewModel = .init(from: provider, onDismiss: { [weak self] in
            self?.marketsListOrderBottomSheetViewModel = nil
        })
    }

    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        let tokenDetailsCoordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )
        tokenDetailsCoordinator.start(with: .init(info: tokenInfo, style: .marketsSheet))

        self.tokenDetailsCoordinator = tokenDetailsCoordinator
    }
}

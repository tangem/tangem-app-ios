//
//  MarketsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root Published

    @Published private(set) var rootViewModel: MarketsViewModel?

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("MarketsCoordinator deinit")
    }

    // MARK: - Implementation

    func start(with options: MarketsCoordinator.Options) {
        rootViewModel = .init(
            quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
            coordinator: self
        )
    }

    private func _openMarketsTokenDetails(with model: MarketsTokenModel) {
        let detailsCoordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )
        detailsCoordinator.start(
            with: .init(info: model, style: .marketsSheet)
        )

        tokenDetailsCoordinator = detailsCoordinator
    }
}

extension MarketsCoordinator {
    struct Options {}
}

extension MarketsCoordinator: MarketsRoutable {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        marketsListOrderBottomSheetViewModel = .init(from: provider, onDismiss: { [weak self] in
            self?.marketsListOrderBottomSheetViewModel = nil
        })
    }

    func openMarketsTokenDetails(tokenSymbol: String, tokenId: String) {
        let model = MarketsTokenModel(tokenSymbol: tokenSymbol, tokenId: tokenId)
        _openMarketsTokenDetails(with: model)
    }

    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        _openMarketsTokenDetails(with: tokenInfo)
    }
}

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

    @Published var tokenMarketsDetailsCoordinator: TokenMarketsDetailsCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implementation

    func start(with options: MarketsCoordinator.Options) {
        rootViewModel = .init(
            quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
            coordinator: self
        )
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

    func openTokenMarketsDetails(for tokenInfo: MarketsTokenModel) {
        let tokenMarketsDetailsCoordinator = TokenMarketsDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenMarketsDetailsCoordinator = nil
            }
        )
        tokenMarketsDetailsCoordinator.start(with: .init(info: tokenInfo, style: .marketsSheet))

        self.tokenMarketsDetailsCoordinator = tokenMarketsDetailsCoordinator
    }
}

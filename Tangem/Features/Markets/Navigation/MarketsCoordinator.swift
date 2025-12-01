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

    @Published private(set) var rootState: StateView?

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
        if FeatureProvider.isAvailable(.newShtorka) {
            let viewModel = MarketsMainViewModel(coordinator: self)
            rootState = .main(viewModel: viewModel)
        } else {
            let viewModel = MarketsViewModel(
                quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
                coordinator: self
            )

            rootState = .markets(viewModel: viewModel)
        }
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

extension MarketsCoordinator: MarketsMainRoutable {}

extension MarketsCoordinator {
    enum StateView: Identifiable, Hashable, Equatable {
        case markets(viewModel: MarketsViewModel)
        case main(viewModel: MarketsMainViewModel)

        var id: String {
            switch self {
            case .markets: return "markets_token_list"
            case .main: return "main_markets_page"
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: MarketsCoordinator.StateView, rhs: MarketsCoordinator.StateView) -> Bool {
            lhs.id == rhs.id
        }
    }
}

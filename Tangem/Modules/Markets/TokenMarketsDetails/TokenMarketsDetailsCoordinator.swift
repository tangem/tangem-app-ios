//
//  TokenMarketsDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class TokenMarketsDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: TokenMarketsDetailsViewModel? = nil
    @Published var networkSelectorViewModel: MarketsTokensNetworkSelectorViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(tokenInfo: options.info, dataProvider: .init(), coordinator: self)
    }
}

extension TokenMarketsDetailsCoordinator {
    struct Options {
        let info: MarketsTokenModel
    }
}

extension TokenMarketsDetailsCoordinator: TokenMarketsDetailsRoutable {
    func openTokenSelector(with coinModel: CoinModel) {
        networkSelectorViewModel = MarketsTokensNetworkSelectorViewModel(coinModel: coinModel)
    }
}

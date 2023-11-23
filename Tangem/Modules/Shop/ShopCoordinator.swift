//
//  ShopCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ShopCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Child view models

    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil

    @Published var webShopUrl: URL? = nil

    // MARK: - Private helpers

    @Published var emptyModel: Int? = nil // Fix single navigation link issue

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: ShopCoordinator.Options = .init()) {
        Analytics.log(.shopScreenOpened)

        if let webShopUrl = ShopWebHelper().webShopUrl {
            self.webShopUrl = webShopUrl
        }
    }
}

extension ShopCoordinator {
    struct Options {}
}

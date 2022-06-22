//
//  ShopCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ShopCoordinator: CoordinatorObject {
    var dismissAction: () -> Void = {}
    var popToRootAction: (PopToRootOptions) -> Void = { _ in }
    
    //MARK: - Main view model
    @Published private(set) var shopViewModel: ShopViewModel? = nil
    
    //MARK: - Child view models
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    
    @Published var webShopUrl: URL? = nil
    
    //MARK: - Private helpers
    @Published var emptyModel: Int? = nil //Fix single navigation link issue
    
    func start(with options: ShopCoordinator.Options = .init()) {
        if Locale.current.regionCode == "RU" {
            webShopUrl = URL(string: "https://mv.tangem.com")
        } else {
            shopViewModel = ShopViewModel(coordinator: self)
        }
    }
}

extension ShopCoordinator {
    struct Options {
        
    }
}

extension ShopCoordinator: ShopViewRoutable {
    func openWebCheckout(at url: URL) {
        pushedWebViewModel = WebViewContainerViewModel(url: url,
                                                       title: "shop_web_checkout_title".localized,
                                                       addLoadingIndicator: true)
    }
    
    func closeWebCheckout() {
        pushedWebViewModel = nil
    }
}

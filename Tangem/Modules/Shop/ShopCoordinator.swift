//
//  ShopCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ShopCoordinator: ObservableObject, Identifiable {
    //MARK: - View models
    @Published private(set) var shopViewModel: ShopViewModel? = nil
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    
    @Published var webShopUrl: URL? = nil
    
    func start() {
        if Locale.current.regionCode == "RU" {
            webShopUrl = URL(string: "https://mv.tangem.com")
        } else {
            shopViewModel = ShopViewModel(coordinator: self)
        }
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

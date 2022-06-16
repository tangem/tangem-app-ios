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
    
    @Published var webShopUrl: URL? = nil
    
    func start() {
        if Locale.current.regionCode == "RU" {
            webShopUrl = URL(string: "https://mv.tangem.com")
        } else {
            shopViewModel = ShopViewModel()
        }
    }
}

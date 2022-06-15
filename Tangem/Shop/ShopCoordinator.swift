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
    @Published private(set) var shopViewModel: ShopViewModel = .init()
}

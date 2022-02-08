//
//  ShopViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ShopViewModel: ViewModel, ObservableObject {
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var shopifyService: ShopifyService!
    
    var bag = Set<AnyCancellable>()
}

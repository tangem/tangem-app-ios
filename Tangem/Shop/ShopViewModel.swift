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
    enum ProductVariant: String, CaseIterable, Identifiable {
        case twoCards, threeCards
        var id: Self { self }
    }
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var shopifyService: ShopifyService!
    
    var bag = Set<AnyCancellable>()
    
    // MARK: - Input
    @Published var selectedVariant: ProductVariant = .threeCards
    #warning("TODO")
    @Published var canShowApplePay = true
    @Published var showingApplePay = false
    @Published var showingWebCheckout = false
    
    // MARK: - Output
    @Published var totalAmountWithoutDiscount: String? = nil
    @Published var totalAmount = ""
}

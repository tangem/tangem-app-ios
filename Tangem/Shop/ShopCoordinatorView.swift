//
//  ShopCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ShopCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ShopCoordinator
    
    var body: some View {
        NavigationView {
            ShopContainerView(viewModel: coordinator.shopViewModel)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

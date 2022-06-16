//
//  TokenListCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

import SwiftUI

struct TokenListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenListCoordinator
    
    var body: some View {
        NavigationView {
            TokenListView(viewModel: coordinator.tokenListViewModel)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

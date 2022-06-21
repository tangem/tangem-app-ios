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
        if let webShopUrl = coordinator.webShopUrl {
            SafariView(url: webShopUrl)
        } else {
            NavigationView {
                if let order = coordinator.shopViewModel?.order { //[REDACTED_TODO_COMMENT]
                    ShopOrderView(order: order)
                } else if coordinator.shopViewModel?.pollingForOrder == true {
                    ShopOrderProgressView()
                } else {
                    ShopView(viewModel: coordinator.shopViewModel!)
                        .navigation(item: $coordinator.pushedWebViewModel) {
                            WebViewContainer(viewModel: $0)
                                .edgesIgnoringSafeArea(.all)
                        }
                        .navigation(item: $coordinator.emptyModel) { _ in
                            EmptyView()
                        }
                }
            }
            .navigationViewStyle(.stack)
        }
    }
}

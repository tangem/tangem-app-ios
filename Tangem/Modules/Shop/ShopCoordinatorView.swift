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
                if let order = coordinator.shopViewModel?.order { // [REDACTED_TODO_COMMENT]
                    ShopOrderView(order: order)
                } else if coordinator.shopViewModel?.pollingForOrder == true {
                    ShopOrderProgressView()
                } else {
                    ShopView(viewModel: coordinator.shopViewModel!)
                        .navigationLinks(links)
                }
            }
            .navigationViewStyle(.stack)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedWebViewModel) {
                WebViewContainer(viewModel: $0)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigation(item: .constant(nil)) {
                EmptyView()
            }
    }
}

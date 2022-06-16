//
//  ShopContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShopContainerView: View {
    @ObservedObject var viewModel: ShopViewModel
    
    var body: some View {
        if let webShopUrl = viewModel.webShopUrl {
            SafariView(url: webShopUrl)
        } else {
            NavigationView {
                if let order = viewModel.order {
                    ShopOrderView(order: order)
                } else if viewModel.pollingForOrder {
                    ShopOrderProgressView()
                } else {
                    ShopView(viewModel: viewModel)
                }
            }
        }
    }
}

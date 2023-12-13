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
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .emptyNavigationLink()
    }
}

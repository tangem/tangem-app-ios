//
//  PriceAlertBellView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct PriceAlertBellView: View {
    @ObservedObject var viewModel: PriceAlertBellViewModel

    var body: some View {
        NavigationBarButton.priceAlert(isActive: viewModel.isSubscribed, action: viewModel.toggleTapped)
            .redesigned()
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.tokenDetailsSubscribeButton)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}

//
//  OnrampPaymentMethodsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct OnrampPaymentMethodsView: View {
    @ObservedObject var viewModel: OnrampPaymentMethodsViewModel

    var body: some View {
        GroupedScrollView(spacing: 0) {
            SelectableSection(viewModel.paymentMethods) { paymentMethod in
                OnrampPaymentMethodRowView(
                    isSelected: viewModel.selectedPaymentMethodID == paymentMethod.id,
                    data: paymentMethod
                )
            }
            .separatorPadding(.init(leading: 62, trailing: SelectionOverlay.Constants.secondStrokeLineWidth))
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodsList)
        }
        .background(Colors.Background.primary)
        .navigationTitle(Text(Localization.onrampPayWith))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }
}

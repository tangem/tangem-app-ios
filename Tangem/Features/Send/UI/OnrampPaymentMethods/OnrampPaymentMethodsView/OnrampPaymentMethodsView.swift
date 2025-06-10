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

struct OnrampPaymentMethodsView: View {
    @ObservedObject var viewModel: OnrampPaymentMethodsViewModel

    var body: some View {
        GroupedScrollView(spacing: 0) {
            ForEach(viewModel.paymentMethods) { paymentMethod in
                OnrampPaymentMethodRowView(data: paymentMethod)

                if paymentMethod.id != viewModel.paymentMethods.last?.id {
                    Separator(height: .minimal, color: Colors.Stroke.primary)
                        .padding(.leading, 62)
                }
            }
        }
        .background(Colors.Background.primary)
        .navigationTitle(Text(Localization.onrampPayWith))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }
}

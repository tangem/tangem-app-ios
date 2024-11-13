//
//  OnrampPaymentMethodsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampPaymentMethodsView: View {
    @ObservedObject var viewModel: OnrampPaymentMethodsViewModel

    var body: some View {
        GroupedScrollView(spacing: 0) {
            ForEach(viewModel.paymentMethods) {
                OnrampPaymentMethodRowView(data: $0)

                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.leading, 62)
            }
        }
        .background(Colors.Background.primary)
        .navigationTitle(Text(Localization.onrampPayWith))
        .alert(item: $viewModel.alert, content: { $0.alert })
    }
}

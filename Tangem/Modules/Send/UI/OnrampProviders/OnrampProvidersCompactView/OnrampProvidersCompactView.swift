//
//  OnrampProvidersCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersCompactView: View {
    @ObservedObject var viewModel: OnrampProvidersCompactViewModel

    var body: some View {
        GroupedSection(viewModel.paymentState) { state in
            switch state {
            case .loading:
                LoadingProvidersRow()
            case .loaded(let data):
                OnrampProvidersCompactProviderView(data: data)
            }
        }
        .innerContentPadding(14)
        .backgroundColor(Colors.Background.action)
        .animation(.default, value: viewModel.paymentState)
    }
}

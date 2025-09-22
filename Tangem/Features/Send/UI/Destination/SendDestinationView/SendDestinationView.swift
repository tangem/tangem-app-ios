//
//  SendDestinationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SendDestinationView: View {
    @ObservedObject var viewModel: SendDestinationViewModel

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.addressViewModel) {
                SendDestinationTextView(viewModel: $0)
            } footer: {
                Text(.init(viewModel.addressDescription))
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .backgroundColor(Colors.Background.action)

            if viewModel.additionalFieldViewModelHasValue {
                GroupedSection(viewModel.additionalFieldViewModel) {
                    SendDestinationTextView(viewModel: $0)
                        .padding(.vertical, 2)
                } footer: {
                    Text(viewModel.additionalFieldDescription)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
                .backgroundColor(Colors.Background.action)
            }

            if viewModel.showSuggestedDestinations,
               let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}

//
//  ExpressSuccessSentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressSuccessSentView: View {
    @ObservedObject private var viewModel: ExpressSuccessSentViewModel

    init(viewModel: ExpressSuccessSentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: .zero) {
                titleView
            
                VStack(spacing: 14) {
                    GroupedSection(viewModel.sourceData) {
                        AmountSummaryView(data: $0)
                    }
                    .verticalPadding(0)
                    .interSectionPadding(12)
                    
                    GroupedSection(viewModel.destinationData) {
                        AmountSummaryView(data: $0)
                    }
                    .verticalPadding(0)
                    .interSectionPadding(12)
                    
                    GroupedSection(viewModel.provider) {
                        ProviderRowView(viewModel: $0)
                    }
                    .verticalPadding(0)
                    .interSectionPadding(12)
                    
                    GroupedSection(viewModel.expressFee) {
                        ExpressFeeRowView(viewModel: $0)
                    }
                    .verticalPadding(0)
                    .interSectionPadding(12)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private var titleView: some View {
        VStack(spacing: 18) {
            Assets.swapInProcessIcon.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            VStack(spacing: 4) {
                Text(Localization.swappingSuccessViewTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text("20 September 2023 at 13:45")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .padding(.vertical, 24)
    }
}

struct ExpressSuccessSentView_Preview: PreviewProvider {
    static let viewModel = ExpressSuccessSentViewModel(
        input: .init(),
        coordinator: ExpressSuccessSentRoutableMock()
    )

    static var previews: some View {
        NavHolder()
            .sheet(item: .constant(viewModel)) {
            ExpressSuccessSentView(viewModel: $0)
        }
    }
}

class ExpressSuccessSentRoutableMock: ExpressSuccessSentRoutable {}

//
//  SuccessSwappingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SuccessSwappingView: View {
    @ObservedObject private var viewModel: SuccessSwappingViewModel

    init(viewModel: SuccessSwappingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Color.clear.frame(height: geometry.size.height * 0.13)

                    VStack(spacing: geometry.size.height * 0.25) {
                        Assets.successBigIcon

                        infoView
                    }
                }

                buttonView
            }
            .navigationBarTitle(Text("swapping_swap".localized), displayMode: .inline)
        }
    }

    private var infoView: some View {
        VStack(spacing: 14) {
            Text("swapping_success".localized)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            VStack(spacing: 0) {
                Text("swapping_swap_of_to".localized(viewModel.fromCurrency))
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)

                Text(viewModel.toCurrency)
                    .style(Fonts.Bold.callout, color: Colors.Text.accent)
            }
        }
    }

    private var buttonView: some View {
        VStack(spacing: 0) {
            Spacer()

            MainButton(text: "common_done".localized, action: viewModel.doneDidTapped)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct SuccessSwappingView_Preview: PreviewProvider {
    static let viewModel = SuccessSwappingViewModel(
        fromCurrency: "1 000 DAI",
        toCurrency: "1 000,36 MATIC",
        coordinator: SwappingCoordinator()
    )

    static var previews: some View {
        NavHolder()
            .sheet(item: .constant(viewModel)) {
                SuccessSwappingView(viewModel: $0)
            }
    }
}

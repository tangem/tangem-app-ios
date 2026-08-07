//
//  TransferView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TransferView: View {
    @ObservedObject var viewModel: TransferViewModel

    var body: some View {
        VStack(spacing: 16) {
            AddFundsStackNavigationBar(
                title: viewModel.title,
                onClose: viewModel.close
            )

            viewModel.tokenInfoViewData.map {
                AddFundsTokenInfoView(viewData: $0)
                    .padding(.top, 64)
            }

            Spacer()

            optionsSection
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .onFirstAppear(perform: viewModel.onAppear)
    }

    private var optionsSection: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.options) { option in
                AddFundsOptionView(viewData: option.viewData, isEnabled: viewModel.isEnabled(option), action: {
                    viewModel.userDidTap(option)
                })
            }
        }
    }
}

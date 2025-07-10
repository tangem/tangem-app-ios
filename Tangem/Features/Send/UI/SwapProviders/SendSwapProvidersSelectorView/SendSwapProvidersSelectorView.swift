//
//  SendSwapProvidersSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets

struct SendSwapProvidersSelectorView: View {
    @ObservedObject var viewModel: SendSwapProvidersSelectorViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.expressChooseProvider, trailing: {
                RoundedButton(style: .icon(Assets.cross, color: Colors.Icon.secondary), action: viewModel.dismiss)
            })
            .padding(.horizontal, 16)

            SelectableSection(viewModel.providerViewModels) { data in
                SendSwapProvidersSelectorProviderView(data: data, isSelected: viewModel.isSelected(data.id).asBinding)
            }
            // Should start when title starts (14 + 36 + 12)
            .separatorPadding(.init(leading: 62, trailing: 14))
            .padding(.horizontal, 14)

            ExpressMoreProvidersSoonView()
                .padding(.all, 16)
        }
        .padding(.vertical, 4)
        .padding(.bottom, 16)
    }
}

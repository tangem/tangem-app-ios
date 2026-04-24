//
//  DynamicAddressesDisableSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct DynamicAddressesDisableSheetView: View {
    @ObservedObject var viewModel: DynamicAddressesDisableSheetViewModel

    var compoundTransaction: Bool {
        if case .compoundTransactionDisable = viewModel.actionType {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            BottomSheetHeaderView(title: "", trailing: {
                NavigationBarButton.close(action: viewModel.dismiss)
            })

            VStack(spacing: 24) {
                mainContent

                actionContent
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var mainContent: some View {
        VStack(spacing: 24) {
            viewModel.icon.icon.image
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(viewModel.icon.tint)
                .padding(.all, 12)
                .background(Circle().fill(viewModel.icon.overlay.opacity(0.1)))

            VStack(spacing: 8) {
                Text(Localization.dynamicAddressesDisableTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(Localization.dynamicAddressesDisableDescription)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, compoundTransaction ? 0 : 16)
    }

    @ViewBuilder
    var actionContent: some View {
        switch viewModel.actionType {
        case .none:
            EmptyView()
        case .disable(let action):
            MainButton(
                title: Localization.commonConfirm,
                isLoading: viewModel.isLoading,
                action: action
            )
            .padding(.top, 16)
        case .compoundTransactionDisable(let compoundViewModel):
            DynamicAddressesCompoundTransactionView(viewModel: compoundViewModel)
        }
    }
}

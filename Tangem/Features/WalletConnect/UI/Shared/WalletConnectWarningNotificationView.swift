//
//  WalletConnectWarningNotificationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectWarningNotificationView: View {
    let viewModel: WalletConnectWarningNotificationViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            viewModel.iconAsset.image
                .resizable()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.title)
                    .style(Fonts.Bold.footnote, color: viewModel.severity.tintColor)

                Text(viewModel.body)
                    .style(Fonts.Regular.footnote, color: bodyTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .background(background)
        .if(viewModel.containerStyle == .standAloneSection) { view in
            view.clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var bodyTextColor: Color {
        switch viewModel.containerStyle {
        case .standAloneSection:
            Colors.Text.primary1
        case .embedded:
            Colors.Text.tertiary
        }
    }

    private var background: some ShapeStyle {
        switch viewModel.containerStyle {
        case .standAloneSection:
            viewModel.severity.backgroundColor
        case .embedded:
            Color.clear
        }
    }
}

private extension WalletConnectWarningNotificationViewModel.Severity {
    var tintColor: Color {
        switch self {
        case .attention: Colors.Text.primary1
        case .critical: Colors.Icon.warning
        }
    }

    var backgroundColor: Color {
        switch self {
        case .attention: Colors.Button.disabled
        case .critical: Colors.Icon.warning.opacity(0.1)
        }
    }
}

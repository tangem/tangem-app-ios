//
//  OnrampStatusScreenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct OnrampStatusScreenView: View {
    @ObservedObject var viewModel: OnrampStatusScreenViewModel
    let transactionTime: String?
    let onClose: () -> Void

    var body: some View {
        StatusScreen(
            title: viewModel.state.title,
            description: transactionTime,
            actionTitle: Localization.commonClose,
            action: onClose
        )
        .appearance(viewModel.state.appearance)
        .assetSlot {
            StatusIcon(viewModel.state.glyph)
                .glow(viewModel.state.glyph != .pending)
                .id(viewModel.state.glyph)
        }
        .details { details }
        .footerCaption(Localization.onrampTransactionStatusFooterText)
    }

    private var details: some View {
        VStack(spacing: 0) {
            TangemUI.Row(title: Localization.onrampTitleYouGet, value: viewModel.cryptoAmount)
                .showDivider()

            TangemUI.Row(title: Localization.txHistoryYouPaid, value: viewModel.fiatAmount)
                .showDivider()

            TangemUI.Row(title: Localization.expressProvider, value: viewModel.providerName)
                .valueAccessory { providerIcon }
                .showDivider(viewModel.externalTxId != nil)

            if let externalTxId = viewModel.externalTxId {
                TangemUI.Row(title: Localization.commonTransactionId, value: externalTxId)
                    .end(icon: DesignSystem.Icons.Copy.regular16)
                    .truncationModes(.init(value: .middle))
                    .onTap(action: viewModel.copyTransactionId)
                    .accessibilityHint(Localization.commonCopy)
            }
        }
    }

    @ViewBuilder
    private var providerIcon: some View {
        if let providerIconURL = viewModel.providerIconURL {
            IconView(url: providerIconURL, size: CGSize(width: 16, height: 16), forceKingfisher: true)
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
    }
}

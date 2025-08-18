//
//  WCTransactionAddressRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct WCTransactionAddressRowView: View {
    let viewModel: WCTransactionAddressRowViewModel

    @State private var frameWidth = CGFloat.zero
    @State private var tooltipIsShown = false

    var body: some View {
        HStack(spacing: 12) {
            iconAndLabel
            address
        }
        .readGeometry(\.frame.width, bindTo: $frameWidth)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(.rect)
        .onTapGesture {
            tooltipIsShown.toggle()
        }
    }

    private var iconAndLabel: some View {
        HStack(spacing: 4) {
            viewModel.icon.image
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)

            Text(viewModel.label)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var address: some View {
        Text(viewModel.address)
            .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            .truncationMode(.middle)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .frame(maxWidth: frameWidth * 0.42, alignment: .trailing)
            .popoverBackport(viewModel.address, isPresented: $tooltipIsShown)
            .textSelection(.enabled)
    }
}

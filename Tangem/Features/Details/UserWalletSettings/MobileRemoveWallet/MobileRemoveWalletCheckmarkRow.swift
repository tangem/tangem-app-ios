//
//  MobileRemoveWalletCheckmarkRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileRemoveWalletCheckmarkRow: View {
    let title: String
    @Binding var isChecked: Bool

    var body: some View {
        HStack(spacing: Layout.spacing) {
            mark
            text
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private func onTap() {
        isChecked.toggle()
    }

    private var mark: some View {
        TangemUI.Checkmark(isOn: $isChecked)
            .expandsHitArea(false)
    }

    private var text: some View {
        Text(title)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Layout

private extension MobileRemoveWalletCheckmarkRow {
    enum Layout {
        static let spacing: CGFloat = 12
    }
}

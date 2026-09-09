//
//  TransferInputTokenModalView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TransferInputTokenModalView: View {
    let items: [TransferInputTokenItem]
    @Binding var selection: TransferInputTokenItem.ID?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.commonChooseNetwork, trailing: { closeButton })
                .titleFont(DesignSystem.Font.bodyMediumToken.font)
                .titleColor(DesignSystem.Color.textPrimary)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.bottom, Constants.headerBottomPadding)

            ScrollView(showsIndicators: false) {
                VStack(spacing: .zero) {
                    ForEach(items) { item in
                        row(item)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

private extension TransferInputTokenModalView {
    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: onClose
        )
        .size(.x11)
        .styleType(.material(.glass))
    }

    func row(_ item: TransferInputTokenItem) -> some View {
        Row(title: item.symbol, subtitle: item.subtitle)
            .start {
                icon(for: item)
            }
            .end {
                checkmark(isChecked: item.id == selection)
            }
            .onTap { selection = item.id }
            .disabled(!item.isOfframpAvailable)
    }

    func icon(for item: TransferInputTokenItem) -> some View {
        TokenIconV2(tokenIconInfo: item.tokenIconInfo, size: .size40)
            .grayscale(!item.isOfframpAvailable)
    }

    @ViewBuilder
    func checkmark(isChecked: Bool) -> some View {
        if isChecked {
            TangemUI.Checkmark(checked: true, action: {})
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Constants

private extension TransferInputTokenModalView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 8
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selection: TransferInputTokenItem.ID? = TransferInputTokenItem.previewList.first?.id

    TransferInputTokenModalView(
        items: TransferInputTokenItem.previewList,
        selection: $selection,
        onClose: {}
    )
}
#endif

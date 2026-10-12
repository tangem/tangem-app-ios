//
//  TransferInputRailModalView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPay
import TangemUI

struct TransferInputRailModalView: View {
    let items: [TransferInputRailItem]
    @Binding var selection: TangemPayBankAccountRail?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.tangempayWithdrawBankSelectRoute, trailing: { closeButton })
                .titleFont(DesignSystem.Font.bodyMediumToken.font)
                .titleColor(DesignSystem.Color.textPrimary)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.bottom, Constants.headerBottomPadding)

            VStack(spacing: .zero) {
                ForEach(items) { item in
                    row(item)
                }
            }
        }
    }
}

// MARK: - Subviews

private extension TransferInputRailModalView {
    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: onClose
        )
        .size(.x11)
        .styleType(.material(.glass))
    }

    func icon(for item: TransferInputRailItem) -> some View {
        item.icon.image
            .resizable()
            .scaledToFit()
            .frame(width: Constants.iconSide, height: Constants.iconSide)
    }

    func checkmark(isChecked: Bool) -> some View {
        TangemUI.Checkmark(checked: isChecked, action: {})
            .allowsHitTesting(false)
    }

    func row(_ item: TransferInputRailItem) -> some View {
        Row(title: item.title, subtitle: item.etaText, value: item.feeText)
            .start {
                icon(for: item)
            }
            .end {
                checkmark(isChecked: item.rail == selection)
            }
            .onTap { selection = item.rail }
    }
}

// MARK: - Constants

private extension TransferInputRailModalView {
    enum Constants {
        static let iconSide: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 8
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selection: TangemPayBankAccountRail? = .ach

    TransferInputRailModalView(
        items: TransferInputRailItem.previewList,
        selection: $selection,
        onClose: {}
    )
}
#endif

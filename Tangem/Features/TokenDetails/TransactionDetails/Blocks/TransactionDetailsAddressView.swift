//
//  TransactionDetailsAddressView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransactionDetailsAddressViewData {
    /// Row label (subtitle), e.g. "From address" / "Recipient" / "From" / "To".
    let label: String
    let actor: Actor

    enum Actor {
        case address(full: String, truncated: String, onCopy: () -> Void)
        case contact(name: String, onCopy: (() -> Void)?)
        case account(name: String)
    }
}

struct TransactionDetailsAddressView: View {
    let data: TransactionDetailsAddressViewData

    @ScaledMetric private var iconSide: CGFloat = 40

    var body: some View {
        TangemRow(title: title, subtitle: data.label)
            .lineOrder(.secondaryFirst)
            .verticalAlignment(.center)
            .start { startIcon }
            .end { endAccessory }
            .background(
                DesignSystem.Color.bgTertiary,
                in: RoundedRectangle(cornerRadius: 24)
            )
    }

    private var title: String {
        switch data.actor {
        case .address(_, let truncated, _): truncated
        case .contact(let name, _): name
        case .account(let name): name
        }
    }

    private var copyAction: (() -> Void)? {
        switch data.actor {
        case .address(_, _, let onCopy): onCopy
        case .contact(_, let onCopy): onCopy
        case .account: nil
        }
    }

    @ViewBuilder
    private var startIcon: some View {
        switch data.actor {
        case .address(let full, _, _):
            AddressIconView(viewModel: AddressIconViewModel(address: full))
                .frame(width: iconSide, height: iconSide)
        case .contact(let name, _):
            initialsAvatar(name: name, shape: .circle)
        case .account(let name):
            initialsAvatar(name: name, shape: .roundedRect)
        }
    }

    @ViewBuilder
    private var endAccessory: some View {
        if let onCopy = copyAction {
            Button(action: onCopy) {
                DesignSystem.Icons.Copy.regular20.image
                    .renderingMode(.template)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .padding(8)
                    .background(Circle().fill(DesignSystem.Color.bgOpaquePrimary))
            }
            .buttonStyle(.plain)
        }
    }

    private enum AvatarShape { case circle, roundedRect }

    private func initialsAvatar(name: String, shape: AvatarShape) -> some View {
        let initial = name.first.map { String($0).uppercased() } ?? "?"
        return Group {
            switch shape {
            case .circle:
                Circle().fill(DesignSystem.Color.bgOpaquePrimary)
            case .roundedRect:
                RoundedRectangle(cornerRadius: iconSide * 0.3, style: .continuous)
                    .fill(DesignSystem.Color.bgStatusInfoSubtle)
            }
        }
        .frame(width: iconSide, height: iconSide)
        .overlay {
            Text(initial)
                .style(DesignSystem.Font.bodyMediumToken, color: avatarTextColor(shape))
        }
    }

    private func avatarTextColor(_ shape: AvatarShape) -> Color {
        switch shape {
        case .circle: DesignSystem.Color.textSecondary
        case .roundedRect: DesignSystem.Color.iconStatusInfo
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Counterparty actors") {
    VStack(spacing: 16) {
        TransactionDetailsAddressView(data: .init(
            label: "From address",
            actor: .address(full: "0x33Bd321fS5f9aF12c0Bd987654321ABCDEFga21412B", truncated: "33Bd321fS...ga21412B", onCopy: {})
        ))

        TransactionDetailsAddressView(data: .init(
            label: "Recipient",
            actor: .contact(name: "Alice", onCopy: {})
        ))

        TransactionDetailsAddressView(data: .init(
            label: "To",
            actor: .account(name: "Family")
        ))
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
#endif // DEBUG

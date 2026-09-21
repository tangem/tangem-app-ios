//
//  TransferSuccessStatusView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransferSuccessStatusView: View {
    let model: Model
    let onClose: () -> Void

    var body: some View {
        StatusScreen(
            title: model.title,
            description: model.dateText,
            actionTitle: Constants.closeTitle,
            action: onClose
        )
        .appearance(.info)
        .assetSlot {
            StatusIcon(.checkmark)
                .tint(DesignSystem.Color.iconStatusInfo)
        }
        .details { detailRows }
    }

    @ViewBuilder
    private var detailRows: some View {
        VStack(spacing: 0) {
            ForEach(model.details) { detail in
                TangemUI.Row(title: detail.title, value: detail.value)
                    .showDivider(detail.id != model.details.last?.id)
            }
        }
    }
}

// MARK: - Model

extension TransferSuccessStatusView {
    struct Model: Identifiable {
        let id = UUID()
        let title: String
        let dateText: String
        let details: [Detail]
    }

    struct Detail: Identifiable {
        let id: ID
        let title: String
        let value: String
    }
}

extension TransferSuccessStatusView.Detail {
    enum ID: Hashable {
        case recipient
        case bankName
        case accountNumber
    }
}

// MARK: - Constants

private extension TransferSuccessStatusView {
    enum Constants {
        static let closeTitle = "Close"
    }
}

// MARK: - Previews

#Preview {
    TransferSuccessStatusView(
        model: TransferSuccessStatusView.Model(
            title: "Sending $500",
            dateText: "May 2, 2028 at 9:41 AM",
            details: [
                .init(id: .recipient, title: "Recipient", value: "Saburo Arasaka"),
                .init(id: .bankName, title: "Bank name", value: "Arasaka Bank"),
                .init(id: .accountNumber, title: "Account number", value: "0000000000"),
            ]
        ),
        onClose: {}
    )
}

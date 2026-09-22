//
//  TransactionDetailsSignaturesView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransactionDetailsSignaturesViewData: Equatable {
    let title: String
    /// Includes the initiator's own signature, so an operation that exists never reads zero.
    let collectedCount: Int
    let membersCount: Int
}

/// The progress of a joint account operation towards the signatures it needs, and the way to see who has answered.
struct TransactionDetailsSignaturesView: View {
    let data: TransactionDetailsSignaturesViewData
    let onTap: () -> Void

    var body: some View {
        Row(title: data.title)
            .titleAccessory {
                DesignSystem.Icons.Info.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .end {
                JointAccountSignatureMarks(
                    signedMembersCount: data.collectedCount,
                    totalMembersCount: data.membersCount
                )
            }
            .onTap(onTap)
            .background(DesignSystem.Color.bgStatusWarningSubtle)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }
}

// MARK: - Constants

private extension TransactionDetailsSignaturesView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
    }
}

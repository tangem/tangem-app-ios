//
//  PolymarketPositionNotice.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketPositionNoticeView: View {
    let notice: PolymarketPositionNotice

    var body: some View {
        MessageBanner(
            title: AttributedString(notice.title),
            description: AttributedString(notice.message)
        )
        .variant(.warning)
        .glowRing(.warning)
        .slotEnd { hint }
    }

    private var hint: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: Constants.hintSide))
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }
}

// MARK: - Notice

public enum PolymarketPositionNotice: Hashable, Sendable, CaseIterable {
    case pendingResolution
    case disputed

    var title: String {
        switch self {
        case .pendingResolution: Localization.predictionPositionsPendingTitle
        case .disputed: Localization.predictionPositionsDisputedTitle
        }
    }

    var message: String {
        switch self {
        case .pendingResolution: Localization.predictionPositionsPendingDescription
        case .disputed: Localization.predictionPositionsDisputedDescription
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionNoticeView {
    enum Constants {
        static let hintSide: CGFloat = 20
    }
}

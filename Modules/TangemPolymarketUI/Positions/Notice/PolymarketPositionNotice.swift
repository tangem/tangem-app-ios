//
//  PolymarketPositionNotice.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
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

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch self {
        case .pendingResolution: "Awaiting final result"
        case .disputed: "Under dispute"
        }
    }

    var message: String {
        switch self {
        case .pendingResolution:
            "Market closed. It is in a short Polymarket review window. Your position should resolve soon."
        case .disputed:
            "The result has been challenged by participants and is under Polymarket review. "
                + "Your position settles automatically once it's final."
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionNoticeView {
    enum Constants {
        static let hintSide: CGFloat = 20
    }
}

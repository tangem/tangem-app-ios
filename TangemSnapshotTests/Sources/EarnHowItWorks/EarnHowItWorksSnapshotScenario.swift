//
//  EarnHowItWorksSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum EarnHowItWorksSnapshotScenario: String, SnapshotScenario {
    case lendingOnAave
    case highYieldVault
    case highYieldVaultCompact
    case highYieldVaultLargeText
    case highYieldVaultRTL

    var layoutDirection: LayoutDirection {
        self == .highYieldVaultRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .highYieldVaultLargeText ? .xxxLarge : .large
    }

    @MainActor
    var body: some View {
        EarnHowItWorksView(content: content, onLearnMore: { _ in }, onGotIt: {})
            .padding(.horizontal, Constants.modalHorizontalPadding)
            .frame(width: self == .highYieldVaultCompact ? Constants.compactWidth : Constants.regularWidth)
    }
}

private extension EarnHowItWorksSnapshotScenario {
    var content: EarnHowItWorks {
        switch self {
        case .lendingOnAave:
            .lendingOnAavePreview
        case .highYieldVault, .highYieldVaultCompact, .highYieldVaultLargeText, .highYieldVaultRTL:
            .highYieldVaultPreview
        }
    }
}

// MARK: - Constants

private extension EarnHowItWorksSnapshotScenario {
    enum Constants {
        static let regularWidth: CGFloat = 402
        static let compactWidth: CGFloat = 375
        static let modalHorizontalPadding: CGFloat = 8
    }
}

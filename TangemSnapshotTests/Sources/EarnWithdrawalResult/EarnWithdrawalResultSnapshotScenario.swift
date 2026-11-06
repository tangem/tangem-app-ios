//
//  EarnWithdrawalResultSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum EarnWithdrawalResultSnapshotScenario: String, SnapshotScenario {
    case vaultWithdrawn
    case vaultInProgress
    case lendingOnAaveWithdrawn

    var canvases: [SnapshotCanvas] { [.screen(.compact), .screen(.large)] }

    @MainActor
    var body: some View {
        EarnWithdrawalResultContentView(state: state, action: { _ in })
            .environment(\._accessibilityReduceMotion, true)
    }
}

private extension EarnWithdrawalResultSnapshotScenario {
    var state: EarnWithdrawalResultContentView.StateModel {
        switch self {
        case .vaultWithdrawn: .preview(status: .withdrawn, withdrawalPeriod: "Up to 48 hours")
        case .vaultInProgress: .preview(status: .inProgress, withdrawalPeriod: "Up to 48 hours")
        case .lendingOnAaveWithdrawn: .preview(status: .withdrawn, withdrawalPeriod: "Usually instant")
        }
    }
}

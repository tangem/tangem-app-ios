//
//  CollectiblesWelcomeSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum CollectiblesWelcomeSnapshotScenario: String, SnapshotScenario {
    case welcome

    var canvases: [SnapshotCanvas] { [.screen(.compact), .screen(.large)] }

    @MainActor
    var body: some View {
        CollectiblesWelcomeView(
            viewModel: CollectiblesWelcomeViewModel(routable: nil, signingActionButtonType: .requiredNFCInteraction),
            dismissStyle: .back,
            onDismiss: {}
        )
    }
}

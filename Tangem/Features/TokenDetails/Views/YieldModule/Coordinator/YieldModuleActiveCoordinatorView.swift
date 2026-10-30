//
//  YieldModuleActiveCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct YieldModuleActiveCoordinatorView: View {
    @ObservedObject var coordinator: YieldModuleActiveCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                YieldModuleActiveContentV2View(viewModel: viewModel)
                    .interactiveDismissDisabled()
            }
        }
        .modal(
            item: $coordinator.claimViewModel,
            size: YieldModuleClaimModal.size,
            contentLayout: YieldModuleClaimModal.contentLayout,
            dragIndicator: .hidden,
            navigation: YieldModuleClaimModal.navigation,
            onDismiss: coordinator.claimSheetDidDismiss,
            content: { YieldModuleClaimView(viewModel: $0) }
        )
    }
}

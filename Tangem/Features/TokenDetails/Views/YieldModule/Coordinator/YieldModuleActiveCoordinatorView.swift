//
//  YieldModuleActiveCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct YieldModuleActiveCoordinatorView: View {
    @ObservedObject var coordinator: YieldModuleActiveCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                if coordinator.usesIncentiveDesign {
                    YieldModuleActiveContentV2View(viewModel: viewModel)
                        .interactiveDismissDisabled()
                } else {
                    YieldModuleActiveContentView(viewModel: viewModel)
                }
            }
        }
        .background {
            claimModal
        }
    }

    @ViewBuilder
    private var claimModal: some View {
        if let viewModel = coordinator.claimViewModel {
            YieldModuleClaimModal(
                viewModel: viewModel,
                isPresented: $coordinator.isClaimSheetShown,
                onDismissed: coordinator.claimSheetDidDismiss
            )
            .id(viewModel.id)
        }
    }
}

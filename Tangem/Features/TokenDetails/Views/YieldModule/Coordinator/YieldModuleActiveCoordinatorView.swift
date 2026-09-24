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
                YieldModuleActiveContentView(viewModel: viewModel)
            }
        }
        .sheet(item: $coordinator.claimViewModel) { viewModel in
            YieldModuleClaimView(viewModel: viewModel)
        }
    }
}

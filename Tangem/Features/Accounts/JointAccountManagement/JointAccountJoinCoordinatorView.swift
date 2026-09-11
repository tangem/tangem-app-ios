//
//  JointAccountJoinCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct JointAccountJoinCoordinatorView: View {
    @ObservedObject var coordinator: JointAccountJoinCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Color.bgPrimary.ignoresSafeArea()

                if let rootViewModel = coordinator.rootViewModel {
                    JointAccountJoinView(viewModel: rootViewModel)
                }
            }
        }
    }
}

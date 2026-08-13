//
//  JointAccountManagementCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct JointAccountManagementCoordinatorView: View {
    @ObservedObject var coordinator: JointAccountManagementCoordinator

    var body: some View {
        NavigationStack {
            if let rootViewModel = coordinator.rootViewModel {
                JointAccountOnboardingView(viewModel: rootViewModel)
            }
        }
    }
}

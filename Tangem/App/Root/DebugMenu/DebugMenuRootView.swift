//
//  DebugMenuRootView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct DebugMenuRootView: View {
    @ObservedObject var coordinator: EnvironmentSetupCoordinator
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            EnvironmentSetupCoordinatorView(coordinator: coordinator)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close", action: onClose)
                    }
                }
        }
    }
}

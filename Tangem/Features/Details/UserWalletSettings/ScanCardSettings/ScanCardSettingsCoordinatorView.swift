//
//  ScanCardSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

struct ScanCardSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ScanCardSettingsCoordinator

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            ScanCardSettingsView(viewModel: rootViewModel)
                .navigationLinks(links)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.cardSettingsCoordinator) {
                CardSettingsCoordinatorView(coordinator: $0)
            }
    }
}

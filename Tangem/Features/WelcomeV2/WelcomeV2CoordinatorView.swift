//
//  WelcomeV2CoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeV2CoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeV2Coordinator

    var body: some View {
        NavigationStack {
            content
        }
    }

    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                WelcomeV2View(viewModel: rootViewModel)
            }
        }
    }
}

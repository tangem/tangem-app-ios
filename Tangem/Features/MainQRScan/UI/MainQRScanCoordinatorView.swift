//
//  MainQRScanCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainQRScanCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainQRScanCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                MainQRScanView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.imagePickerModel) {
                PhotoSelectorView(viewModel: $0)
                    .edgesIgnoringSafeArea(.all)
            }
    }
}

//
//  LegacySendCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct LegacySendCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: LegacySendCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.sendViewModel {
                LegacySendView(viewModel: model)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        VStack {
            NavHolder()
                .sheet(item: $coordinator.mailViewModel) {
                    MailView(viewModel: $0)
                }
                .sheet(item: $coordinator.qrScanViewModel) {
                    LegacyQRScanView(viewModel: $0)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}

//
//  ExchangeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExchangeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ExchangeCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.exchangeViewModel {
                ExchangeView(viewModel: model)
            }
        }
    }
}

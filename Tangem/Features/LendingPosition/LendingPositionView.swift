//
//  LendingPositionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingPositionView: View {
    @ObservedObject var viewModel: LendingPositionViewModel

    var body: some View {
        LendingPositionContentView(state: viewModel.state, calculator: viewModel.calculator, action: viewModel.handle)
            .onAppear(perform: viewModel.onAppear)
    }
}

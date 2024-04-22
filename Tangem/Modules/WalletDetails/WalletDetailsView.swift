//
//  WalletDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletDetailsView: View {
    @ObservedObject private var viewModel: WalletDetailsViewModel

    init(viewModel: WalletDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct WalletDetailsView_Preview: PreviewProvider {
    static let viewModel = WalletDetailsViewModel(coordinator: WalletDetailsCoordinator())

    static var previews: some View {
        WalletDetailsView(viewModel: viewModel)
    }
}

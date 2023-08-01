//
//  SingleWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleWalletMainContentView: View {
    @ObservedObject var viewModel: SingleWalletMainContentViewModel

    var body: some View {
        VStack {
            Text("Hello, single wallet!")
        }
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel = SingleWalletMainContentViewModel(coordinator: MainCoordinator())

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
    }
}

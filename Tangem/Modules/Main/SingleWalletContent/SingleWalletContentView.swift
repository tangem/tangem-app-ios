//
//  SingleWalletContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleWalletContentView: View {
    @ObservedObject var viewModel: SingleWalletContentViewModel

    var body: some View {
        VStack {
            Text("Hello, single wallet!")
        }
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel = SingleWalletContentViewModel(coordinator: SingleWalletContentCoordinator())

    static var previews: some View {
        SingleWalletContentView(viewModel: viewModel)
    }
}

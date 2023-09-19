//
//  NetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NetworkSelectorView: View {
    @ObservedObject private var viewModel: NetworkSelectorViewModel

    init(viewModel: NetworkSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct NetworkSelectorView_Preview: PreviewProvider {
    static let viewModel = NetworkSelectorViewModel(coordinator: NetworkSelectorCoordinator())

    static var previews: some View {
        NetworkSelectorView(viewModel: viewModel)
    }
}

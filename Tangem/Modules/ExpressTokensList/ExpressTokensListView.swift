//
//  ExpressTokensListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressTokensListView: View {
    @ObservedObject private var viewModel: ExpressTokensListViewModel

    init(viewModel: ExpressTokensListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct ExpressTokensListView_Preview: PreviewProvider {
    static let viewModel = ExpressTokensListViewModel(coordinator: ExpressTokensListRoutableMock())

    static var previews: some View {
        ExpressTokensListView(viewModel: viewModel)
    }
}

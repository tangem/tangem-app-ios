//
//  StakeDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakeDetailsView: View {
    @ObservedObject private var viewModel: StakeDetailsViewModel

    init(viewModel: StakeDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct StakeDetailsView_Preview: PreviewProvider {
    static let viewModel = StakeDetailsViewModel(coordinator: StakeDetailsCoordinator())

    static var previews: some View {
        StakeDetailsView(viewModel: viewModel)
    }
}

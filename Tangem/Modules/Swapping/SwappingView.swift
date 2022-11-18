//
//  SwappingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingView: View {
    @ObservedObject private var viewModel: SwappingViewModel

    init(viewModel: SwappingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct SwappingView_Preview: PreviewProvider {
    static let viewModel = SwappingViewModel(coordinator: SwappingCoordinator())

    static var previews: some View {
        SwappingView(viewModel: viewModel)
    }
}

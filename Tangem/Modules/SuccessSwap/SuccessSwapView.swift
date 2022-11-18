//
//  SuccessSwapView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SuccessSwapView: View {
    @ObservedObject private var viewModel: SuccessSwapViewModel

    init(viewModel: SuccessSwapViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct SuccessSwapView_Preview: PreviewProvider {
    static let viewModel = SuccessSwapViewModel(coordinator: SuccessSwapCoordinator())

    static var previews: some View {
        SuccessSwapView(viewModel: viewModel)
    }
}

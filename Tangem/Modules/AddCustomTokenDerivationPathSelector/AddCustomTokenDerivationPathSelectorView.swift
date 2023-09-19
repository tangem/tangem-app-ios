//
//  AddCustomTokenDerivationPathSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenDerivationPathSelectorView: View {
    @ObservedObject private var viewModel: AddCustomTokenDerivationPathSelectorViewModel

    init(viewModel: AddCustomTokenDerivationPathSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct AddCustomTokenDerivationPathSelectorView_Preview: PreviewProvider {
    static let viewModel = AddCustomTokenDerivationPathSelectorViewModel(coordinator: AddCustomTokenDerivationPathSelectorCoordinator())

    static var previews: some View {
        AddCustomTokenDerivationPathSelectorView(viewModel: viewModel)
    }
}

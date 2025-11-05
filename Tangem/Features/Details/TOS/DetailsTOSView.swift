//
//  DetailsTOSView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct DetailsTOSView: View {
    let viewModel: DetailsTOSViewModel

    var body: some View {
        TOSView(viewModel: viewModel.tosViewModel)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

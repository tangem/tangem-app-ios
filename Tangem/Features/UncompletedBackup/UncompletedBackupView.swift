//
//  UncompletedBackupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct UncompletedBackupView: View {
    @ObservedObject private var viewModel: UncompletedBackupViewModel

    init(viewModel: UncompletedBackupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Colors.Old.tangemStoryBackground
            .edgesIgnoringSafeArea(.all)
            .confirmationDialog(viewModel: $viewModel.discardConfirmationDialog)
            .alert(item: $viewModel.error, content: { $0.alert })
            .onAppear(perform: viewModel.onAppear)
            .environment(\.colorScheme, .dark)
    }
}

struct UncompletedBackupView_Preview: PreviewProvider {
    static let viewModel = UncompletedBackupViewModel(coordinator: UncompletedBackupCoordinator())

    static var previews: some View {
        UncompletedBackupView(viewModel: viewModel)
    }
}

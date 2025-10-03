//
//  MobileOnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct MobileOnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: MobileOnboardingSeedPhraseImportViewModel

    var body: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel.importViewModel)
            .onAppear {
                viewModel.onAppear()
            }
            .flowLoadingOverlay(isPresented: viewModel.isCreating)
    }
}

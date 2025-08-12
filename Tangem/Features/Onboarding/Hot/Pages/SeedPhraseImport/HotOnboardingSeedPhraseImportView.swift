//
//  HotOnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: HotOnboardingSeedPhraseImportViewModel

    var body: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel.importViewModel)
            .flowLoadingOverlay(isPresented: viewModel.isCreating)
    }
}

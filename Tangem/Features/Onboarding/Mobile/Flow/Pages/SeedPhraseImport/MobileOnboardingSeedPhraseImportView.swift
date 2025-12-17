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
            .flowLoadingOverlay(isPresented: viewModel.isCreating)
            .background {
                Color.clear.alert(item: $viewModel.alert) { $0.alert }
            }
            // [REDACTED_TODO_COMMENT]
            // became switches between steps without recreating their views.
            .onAppear(perform: viewModel.onAppear)
    }
}

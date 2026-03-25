//
//  MobileOnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MobileOnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: MobileOnboardingSeedPhraseImportViewModel

    var body: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel.importViewModel)
            .background {
                Color.clear.alert(item: $viewModel.alert) { $0.alert }
            }
            .stepsFlowNavBar(title: viewModel.navigationTitle)
            .stepsFlowNavBar(leading: {
                MobileOnboardingFlowNavBarAction.back(handler: viewModel.onBack).view()
            })
            .stepsFlow(isLoading: viewModel.isCreating)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .onDisappear {
                UIApplication.shared.endEditing()
            }
    }
}

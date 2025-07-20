//
//  HotOnboardingSeedPhraseRecoveryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingSeedPhraseRecoveryStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: HotOnboardingSeedPhraseRecoveryViewModel

    init(delegate: HotOnboardingSeedPhraseRecoveryDelegate) {
        viewModel = HotOnboardingSeedPhraseRecoveryViewModel(delegate: delegate)
    }

    func build() -> some View {
        HotOnboardingSeedPhraseRecoveryView(viewModel: viewModel)
    }
}

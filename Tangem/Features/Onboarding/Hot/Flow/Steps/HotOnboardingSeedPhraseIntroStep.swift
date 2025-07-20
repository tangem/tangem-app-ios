//
//  HotOnboardingSeedPhraseIntroStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingSeedPhraseIntroStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: HotOnboardingSeedPhraseIntroViewModel

    init(delegate: HotOnboardingSeedPhraseIntroDelegate) {
        viewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: delegate)
    }

    func build() -> some View {
        HotOnboardingSeedPhraseIntroView(viewModel: viewModel)
    }
}

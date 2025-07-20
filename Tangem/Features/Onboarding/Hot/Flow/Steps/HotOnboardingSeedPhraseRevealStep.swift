//
//  HotOnboardingSeedPhraseRevealStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingSeedPhraseRevealStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: HotOnboardingSeedPhraseRevealViewModel

    init(delegate: HotOnboardingSeedPhraseRevealDelegate) {
        viewModel = HotOnboardingSeedPhraseRevealViewModel(delegate: delegate)
    }

    func build() -> some View {
        HotOnboardingSeedPhraseRevealView(viewModel: viewModel)
    }
}

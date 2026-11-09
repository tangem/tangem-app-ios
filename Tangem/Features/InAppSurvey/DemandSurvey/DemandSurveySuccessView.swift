//
//  DemandSurveySuccessView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct DemandSurveySuccessView: View {
    let onDone: () -> Void

    var body: some View {
        ModalStatus(
            .success,
            title: Localization.surveyDemandSuccessTitle,
            description: Localization.surveyDemandSuccessDescription
        )
        .actions(primary: TangemUI.Button(label: Localization.commonDone, accessibilityLabel: nil, action: onDone))
    }
}

// MARK: - Previews

#Preview {
    DemandSurveySuccessView(onDone: {})
}

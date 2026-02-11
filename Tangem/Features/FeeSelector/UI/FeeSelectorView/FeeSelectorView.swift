//
//  FeeSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct FeeSelectorView: View {
    @ObservedObject private var viewModel: FeeSelectorViewModel
    private let headerSettings: HeaderSettings?
    private let customFeeManualSaveButtonSettings: CustomFeeManualSaveButtonSettings?

    init(
        viewModel: FeeSelectorViewModel,
        headerSettings: HeaderSettings? = .init(),
        customFeeManualSaveButtonSettings: CustomFeeManualSaveButtonSettings? = .init()
    ) {
        self.viewModel = viewModel
        self.headerSettings = headerSettings
        self.customFeeManualSaveButtonSettings = customFeeManualSaveButtonSettings
    }

    var body: some View {
        switch viewModel.viewState {
        case .summary(let feeSelectorSummaryViewModel):
            FeeSelectorSummaryView(viewModel: feeSelectorSummaryViewModel, shouldShowSummaryBottomButton: true)
        case .tokens(let feeSelectorTokensViewModel):
            FeeSelectorTokensView(viewModel: feeSelectorTokensViewModel)
        case .fees(let feeSelectorFeesViewModel, _):
            FeeSelectorFeesView(
                viewModel: feeSelectorFeesViewModel,
                customFeeManualSaveButtonSettings: customFeeManualSaveButtonSettings
            )
        }
    }
}

extension FeeSelectorView {
    struct HeaderSettings {
        let title: String
        let dismissType: FeeSelectorDismissButtonType

        init(
            title: String = Localization.commonNetworkFeeTitle,
            dismissType: FeeSelectorDismissButtonType = .close
        ) {
            self.title = title
            self.dismissType = dismissType
        }
    }

    struct CustomFeeManualSaveButtonSettings {
        let title: String

        init(title: String = Localization.commonDone) {
            self.title = title
        }
    }
}

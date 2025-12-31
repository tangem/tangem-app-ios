//
//  YieldAvailableNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import SwiftUI
import TangemAssets

final class YieldAvailableNotificationViewModel: ObservableObject {
    // MARK: - Properties

    private var apy: Decimal
    private let onButtonTap: (Decimal) -> Void

    // MARK: - Init

    init(apy: Decimal, onButtonTap: @escaping (Decimal) -> Void) {
        self.apy = apy
        self.onButtonTap = onButtonTap
    }

    // MARK: - Public Implementation

    func onGetStartedTap() {
        onButtonTap(apy)
    }

    func makeTitleText() -> AttributedString {
        let space = AttributedString(" ")

        var title = AttributedString(Localization.commonYieldMode)
        title.foregroundColor = Colors.Text.primary1
        title.font = Fonts.Bold.subheadline

        var dot = AttributedString(AppConstants.dotSign)
        dot.foregroundColor = Colors.Text.tertiary
        dot.font = Fonts.Regular.subheadline

        let apyString = AttributedString(Localization.yieldModuleTokenDetailsEarnNotificationApy)
        let formattedApy = AttributedString(PercentFormatter().format(apy, option: .yield))

        var apyText = apyString + space + formattedApy
        apyText.foregroundColor = Colors.Text.accent
        apyText.font = Fonts.Bold.subheadline

        return title + space + dot + space + apyText
    }
}

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

final class YieldAvailableNotificationViewModel {
    enum Style: Equatable {
        case standard
        case promo
    }

    // MARK: - Properties

    let style: Style
    let titleText: AttributedString
    let descriptionText: String

    private let apy: Decimal
    private let onLearnMoreTap: (Decimal) -> Void
    private let onActivateTap: ((Decimal) -> Void)?

    // MARK: - Init

    init(
        apy: Decimal,
        style: Style = .standard,
        onLearnMoreTap: @escaping (Decimal) -> Void,
        onActivateTap: ((Decimal) -> Void)? = nil
    ) {
        self.apy = apy
        self.style = style
        self.onLearnMoreTap = onLearnMoreTap
        self.onActivateTap = onActivateTap

        let formatter = PercentFormatter()

        switch style {
        case .standard:
            titleText = Self.makeStandardTitle(apy: apy, formatter: formatter)
            descriptionText = Localization.yieldModuleTokenDetailsEarnNotificationDescription
        case .promo:
            titleText = Self.makePromoTitle(apy: apy, formatter: formatter)
            descriptionText = Localization.yieldApyBoostBannerSubtitle
        }
    }

    // MARK: - Actions

    func onLearnMoreButtonTap() {
        onLearnMoreTap(apy)
    }

    func onActivateButtonTap() {
        onActivateTap?(apy)
    }
}

// MARK: - Title builders

private extension YieldAvailableNotificationViewModel {
    static func makeStandardTitle(apy: Decimal, formatter: PercentFormatter) -> AttributedString {
        let space = AttributedString(" ")

        var title = AttributedString(Localization.commonYieldMode)
        title.foregroundColor = Colors.Text.primary1
        title.font = Fonts.Bold.subheadline

        var dot = AttributedString(AppConstants.dotSign)
        dot.foregroundColor = Colors.Text.tertiary
        dot.font = Fonts.Regular.subheadline

        let apyString = AttributedString(Localization.yieldModuleTokenDetailsEarnNotificationApy)
        let formattedApy = AttributedString(formatter.format(apy, option: .yield))

        var apyText = apyString + space + formattedApy
        apyText.foregroundColor = Colors.Text.accent
        apyText.font = Fonts.Bold.subheadline

        return title + space + dot + space + apyText
    }

    static func makePromoTitle(apy: Decimal, formatter: PercentFormatter) -> AttributedString {
        let multiplier: Decimal = 3
        let multipliedApy = apy * multiplier

        let heading = styled(Localization.yieldApyBoostBannerTitle, color: Colors.Text.primary1)

        var originalApy = styled(formatter.format(apy, option: .yield))
        originalApy.strikethroughStyle = .single

        let apyLine = styled(Localization.yieldModuleTokenDetailsEarnNotificationApy + " ")
            + originalApy
            + styled(" x\(multiplier) → ")
            + styled(formatter.format(multipliedApy, option: .yield))

        return heading + "\n" + apyLine
    }

    static func styled(_ string: String, color: Color = Colors.Text.accent) -> AttributedString {
        var attr = AttributedString(string)
        attr.foregroundColor = color
        attr.font = Fonts.Bold.subheadline
        return attr
    }
}

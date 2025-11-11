//
//  YieldStatusViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import Combine
import TangemFoundation
import TangemAssets
import TangemLocalization

final class YieldStatusViewModel: ObservableObject {
    lazy var title: AttributedString = makeTitle()

    @Published
    private(set) var state: State

    private let navigationAction: () -> Void

    // MARK: - Dependencies

    private let manager: YieldModuleManager

    init(state: State, manager: YieldModuleManager, navigationAction: @escaping () -> Void = {}) {
        self.state = state
        self.manager = manager
        self.navigationAction = navigationAction
    }

    @MainActor
    func fetchApy() async {}

    func onTapAction() {
        navigationAction()
    }

    private func makeTitle() -> AttributedString {
        var title = AttributedString(Localization.yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceTitle)
        title.foregroundColor = Colors.Text.primary1
        title.font = Fonts.Bold.subheadline

        guard case .active(_, _, let apy) = state, let apy else {
            return title
        }

        let space = AttributedString(" ")

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

extension YieldStatusViewModel {
    enum State: Equatable {
        case loading
        case active(isApproveRequired: Bool, hasUndepositedAmounts: Bool, apy: Decimal?)
        case closing
    }
}

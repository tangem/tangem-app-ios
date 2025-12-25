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

    @Published
    private(set) var warning: WarningType = .none

    private let navigationAction: () -> Void

    // MARK: - Dependencies

    private let yieldInteractor: YieldManagerInteractor
    private let feeConverter: YieldModuleFeeFormatter
    private lazy var dustFilter = YieldModuleDustFilter(feeConverter: feeConverter)

    init(
        state: State,
        yieldInteractor: YieldManagerInteractor,
        feeTokenItem: TokenItem,
        token: TokenItem,
        navigationAction: @escaping () -> Void
    ) {
        self.state = state
        self.yieldInteractor = yieldInteractor
        self.navigationAction = navigationAction
        feeConverter = YieldModuleFeeFormatter(feeCurrency: feeTokenItem, token: token)

        Task { [weak self] in
            await self?.checkWarnings()
        }
    }

    // MARK: - Public Implementation

    func onTapAction() {
        navigationAction()
    }

    // MARK: - Private Implementation

    @MainActor
    private func checkWarnings() async {
        guard case .active(let isApproveRequired, let undepositedAmount, _) = state else {
            setWarningSign(to: .none)
            return
        }

        if isApproveRequired {
            setWarningSign(to: .approveNeeded)
            return
        }

        if let params = try? await yieldInteractor.getCurrentFeeParameters(),
           await dustFilter.filterUndepositedAmount(
               undepositedAmount,
               minimalTopupAmountInFiat: try? await yieldInteractor.getMinAmount(feeParameters: params)
           ) != nil {
            setWarningSign(to: .hasUndepositedAmounts)
            return
        }

        setWarningSign(to: .none)
    }

    private func setWarningSign(to warningType: WarningType) {
        warning = warningType
    }

    private func makeTitle() -> AttributedString {
        var title = AttributedString(Localization.commonYieldMode)
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
        case active(isApproveRequired: Bool, undepositedAmount: Decimal, apy: Decimal?)
        case closing
    }
}

extension YieldStatusViewModel {
    enum WarningType {
        case none
        case approveNeeded
        case hasUndepositedAmounts
    }
}

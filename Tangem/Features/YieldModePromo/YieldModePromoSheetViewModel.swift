//
//  YieldModePromoSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class YieldModePromoSheetViewModel: Identifiable {
    let data: YieldModePromoSheetData

    private let analyticsLogger: YieldModePromoAnalyticsLogger
    private weak var routable: YieldModePromoSheetRoutable?
    private let appearanceSubject = PassthroughSubject<Void, Never>()
    private var isOutcomeHandled = false

    init(
        data: YieldModePromoSheetData,
        routable: YieldModePromoSheetRoutable?,
        analyticsLogger: YieldModePromoAnalyticsLogger = CommonYieldModePromoAnalyticsLogger()
    ) {
        self.data = data
        self.routable = routable
        self.analyticsLogger = analyticsLogger
    }

    // [REDACTED_TODO_COMMENT]
    var title: String {
        "Earn with your crypto\nup to \(PercentFormatter().format(data.apy, option: .yield)) APY"
    }

    var subtitle: String {
        "Put idle coins to work. No lockups, withdraw anytime."
    }

    var tokensCountText: String {
        data.tokensCount == 1 ? "Choose from 1 token" : "Choose from \(data.tokensCount) tokens"
    }

    var actionTitle: String {
        "Try Yield Mode"
    }

    var appearancePublisher: AnyPublisher<Void, Never> {
        appearanceSubject.eraseToAnyPublisher()
    }

    func onAppear() {
        appearanceSubject.send()
    }

    func close() {
        guard let routable, markOutcomeHandled() else {
            return
        }

        analyticsLogger.logClosed(data: data, method: .cross)
        routable.dismissYieldModePromo()
    }

    func tryYieldMode() {
        guard let routable, markOutcomeHandled() else {
            return
        }

        analyticsLogger.logTryYieldMode(data: data)
        routable.dismissYieldModePromo()
        routable.openYieldModeEarn()
    }

    func onDisappear() {
        guard markOutcomeHandled() else {
            return
        }

        analyticsLogger.logClosed(data: data, method: .swipe)
    }

    private func markOutcomeHandled() -> Bool {
        guard !isOutcomeHandled else {
            return false
        }

        isOutcomeHandled = true
        return true
    }
}

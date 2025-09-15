//
//  YieldModulePromoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

final class YieldModulePromoViewModel {
    // MARK: - Properties

    private let walletModel: any WalletModel
    private(set) var apy: String
    private var lastYearReturns: [String: Double] = [:]
    private let networkFee: Decimal
    private let maximumFee: Decimal

    private(set) var tosUrl = URL(string: "https://tangem.com")!
    private(set) var privacyPolicyUrl = URL(string: "https://tangem.com")!
    private(set) var howIrWorksUrl = URL(string: "https://tangem.com")!

    // MARK: - Injected

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Dependencies

    private weak var coordinator: YieldModulePromoCoordinator?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        apy: String,
        lastYearReturns: [String: Double],
        networkFee: Decimal,
        maximumFee: Decimal,
        coordinator: YieldModulePromoCoordinator
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.apy = apy
        self.lastYearReturns = lastYearReturns
        self.networkFee = networkFee
        self.maximumFee = maximumFee
    }

    // MARK: - Public Implementation

    func onHowItWorksTap() {
        safariManager.openURL(howIrWorksUrl)
    }

    func makeTosAndPrivacyString() -> AttributedString {
        let string = Localization.yieldModulePromoScreenTermsDisclaimer(
            Localization.commonTermsOfUse,
            Localization.commonPrivacyPolicy
        )

        var attributedString = AttributedString(string)
        attributedString.foregroundColor = Colors.Text.tertiary
        attributedString.font = Fonts.Regular.footnote

        if let tosRange = attributedString.range(of: Localization.commonTermsOfUse) {
            attributedString[tosRange].link = tosUrl
            attributedString[tosRange].foregroundColor = Colors.Text.accent
        }

        if let privacyRange = attributedString.range(of: Localization.commonPrivacyPolicy) {
            attributedString[privacyRange].link = privacyPolicyUrl
            attributedString[privacyRange].foregroundColor = Colors.Text.accent
        }

        return attributedString
    }
}

struct YieldModuleInfo {
    let apy: String
    let networkFee: Decimal
    let maximumFee: Decimal
    let lastYearReturns: [String: Double]
}

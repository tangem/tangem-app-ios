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
    @Injected(\.safariManager)
    private var safariManager: SafariManager

    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let startFlowFactory: YieldStartFlowFactory
    private weak var coordinator: YieldModulePromoCoordinator?

    // MARK: - Properties

    private let apy: Decimal
    var apyString: String { "\(apy)" }
    private(set) var tosUrl = URL(string: "https://tangem.com")!
    private(set) var privacyPolicyUrl = URL(string: "https://tangem.com")!
    private(set) var howIrWorksUrl = URL(string: "https://tangem.com")!

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        apy: Decimal,
        coordinator: YieldModulePromoCoordinator?,
        startFlowFactory: YieldStartFlowFactory
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.apy = apy
        self.startFlowFactory = startFlowFactory
    }

    // MARK: - Public Implementation

    func onInterestRateInfoTap() {
        coordinator?.openBottomSheet(viewModel: startFlowFactory.makeInterestRateInfoVewModel())
    }

    func onContinueTap() {
        coordinator?.openBottomSheet(viewModel: startFlowFactory.makeStartViewModel())
    }

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

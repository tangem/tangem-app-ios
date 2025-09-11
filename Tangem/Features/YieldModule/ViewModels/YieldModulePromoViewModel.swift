//
//  YieldModulePromoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

final class YieldModulePromoViewModel {
    private let walletModel: any WalletModel
    private(set) var apy: String
    private var lastYearReturns: [String: Double] = [:]
    private let networkFee: Decimal
    private let maximumFee: Decimal

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

    func openInterestRateInfo() {
        coordinator?.openRateInfoSheet(params: .init(lastYearReturns: lastYearReturns))
    }

    func onContinueButtonTapped() {
        coordinator?
            .openStartEarningSheet(
                params: .init(
                    tokenName: walletModel.tokenItem.name,
                    tokenIcon: NetworkImageProvider().provide(by: walletModel.tokenItem.blockchain, filled: true).image,
                    networkFee: networkFee.formatted(),
                    maximumFee: maximumFee.formatted(),
                    blockchainName: walletModel.tokenItem.blockchain.displayName
                )
            )
    }

    func onHowItWorksTap() {
        safariManager.openURL(URL(string: "https://tangem.com")!)
    }

    func onOpenTosTap() {
        safariManager.openURL(URL(string: "https://tangem.com")!)
    }

    func onOpenPrivacyPolicyTap() {
        safariManager.openURL(URL(string: "https://tangem.com")!)
    }
}

struct YieldModuleInfo {
    let apy: String
    let networkFee: Decimal
    let maximumFee: Decimal
    let lastYearReturns: [String: Double]
}

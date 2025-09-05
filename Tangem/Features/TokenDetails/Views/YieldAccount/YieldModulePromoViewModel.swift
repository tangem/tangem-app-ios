//
//  YieldModulePromoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class YieldModulePromoViewModel {
    private(set) var annualYield: String
    private var lastYearReturns: [String: Double] = [:]
    private let tokenImage: Image
    private let networkFee: Double
    private let maximumFee: Double
    private let tokenName: String
    private let blockchainName: String

    // MARK: - Injected

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Dependencies

    private weak var coordinator: YieldModulePromoCoordinator?

    // MARK: - Init

    init(
        tokenName: String,
        annualYield: String,
        lastYearReturns: [String: Double],
        tokenImage: Image,
        networkFee: Double,
        maximumFee: Double,
        blockchainName: String,
        coordinator: YieldModulePromoCoordinator
    ) {
        self.coordinator = coordinator
        self.annualYield = annualYield
        self.lastYearReturns = lastYearReturns
        self.tokenImage = tokenImage
        self.networkFee = networkFee
        self.maximumFee = maximumFee
        self.blockchainName = blockchainName
        self.tokenName = tokenName
    }

    // MARK: - Public Implementation

    func openInterestRateInfo() {
        coordinator?.openRateInfoSheet(params: .init(lastYearReturns: lastYearReturns))
    }

    func onContinueButtonTapped() {
        coordinator?
            .openEarnInfoSheet(
                params: .init(
                    availableFunds: "3.343535",
                    chartData: .init(annualEarnings: [:]),
                    transferMode: "Automatic",
                    status: "Active",
                    blockchainName: blockchainName,
                    networkFee: networkFee.formatted(),
                    tokenName: tokenName
                )
            )

//        coordinator?.openStartEarningSheet(
//            params: .init(
//                tokenName: tokenName,
//                tokenIcon: tokenImage,
//                networkFee: networkFee.formatted(),
//                maximumFee: maximumFee.formatted(),
//                blockchainName: blockchainName
//            )
//        )
    }

    func onHowItWorksTap() {
        safariManager.openURL(URL(string: "tangem.com")!)
    }

    func onOpenTosTap() {
        safariManager.openURL(URL(string: "tangem.com")!)
    }

    func onOpenPrivacyPolicyTap() {
        safariManager.openURL(URL(string: "tangem.com")!)
    }
}

struct YieldModulePromoInfo {
    let tokenName: String
    let annualYield: Double
    let currentFee: Double
    let maxFee: Double
    let blockchainName: String
    let lastYearReturns: [String: Double]
    let tokenImage: Image
}

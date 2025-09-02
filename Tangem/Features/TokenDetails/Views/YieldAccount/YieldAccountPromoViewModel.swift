//
//  YieldAccountPromoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class YieldAccountPromoViewModel {
    private(set) var annualYield: String
    private var lastYearReturns: [String: Double] = [:]
    private let tokenImage: Image
    private let networkFee: Double
    private let maximumFee: Double

    // MARK: - Dependencies

    private weak var coordinator: YieldAccountPromoCoordinator?

    // MARK: - Init

    init(
        annualYield: String,
        lastYearReturns: [String: Double],
        tokenImage: Image,
        networkFee: Double,
        maximumFee: Double,
        coordinator: YieldAccountPromoCoordinator
    ) {
        self.coordinator = coordinator
        self.annualYield = annualYield
        self.lastYearReturns = lastYearReturns
        self.tokenImage = tokenImage
        self.networkFee = networkFee
        self.maximumFee = maximumFee
    }

    // MARK: - Public Implementation

    func openInterestRateInfo() {
        coordinator?.openInterestRateInfo(lastYearReturns: lastYearReturns)
    }

    func onContinueButtonTapped() {
        coordinator?.openStartEarningSheet(networkFee: networkFee.formatted(), tokenImage: tokenImage, maximumFee: maximumFee.formatted())
    }
}

struct YieldAccountPromoInfo {
    let annualYield: Double
    let currentFee: Double
    let maxFee: Double
    let networkName: String
    let lastYearReturns: [String: Double]
    let tokenImage: Image
}

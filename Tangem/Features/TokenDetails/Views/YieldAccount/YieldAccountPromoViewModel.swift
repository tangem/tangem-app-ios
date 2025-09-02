//
//  YieldAccountPromoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldAccountPromoViewModel {
    private(set) var annualYield: String
    private weak var coordinator: YieldAccountPromoCoordinator?
    private var lastYearReturns: [String: Double] = [:]

    init(annualYield: String, lastYearReturns: [String: Double], coordinator: YieldAccountPromoCoordinator) {
        self.coordinator = coordinator
        self.annualYield = annualYield
        self.lastYearReturns = lastYearReturns
    }

    func openInterestRateInfo() {
        coordinator?.openInterestRateInfo(lastYearReturns: lastYearReturns)
    }
}

struct YieldAccountPromoInfo {
    let annualYield: Double
    let currentFee: Double
    let maxFee: Double
    let networkName: String
    let lastYearReturns: [String: Double]
}

//
//  YieldModePromoContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct YieldModePromoContent: Equatable {
    let candidateData: YieldModePromoSheetData
    let topData: YieldModePromoSheetData

    init?(candidate: YieldModePromoCandidateResolver.Candidate, earnResponse: EarnDTO.List.Response) {
        guard let topToken = earnResponse.items.first.map(EarnModelMapper().mapToEarnTokenModel(from:)), topToken.rateValue > 0 else {
            return nil
        }

        candidateData = YieldModePromoSheetData(
            apy: Self.shownApy(candidate.apy),
            tokensCount: earnResponse.meta.total,
            tokenSymbol: candidate.tokenSymbol,
            blockchainName: candidate.blockchainName
        )
        topData = YieldModePromoSheetData(
            apy: Self.shownApy(topToken.rateValue),
            tokensCount: earnResponse.meta.total,
            tokenSymbol: topToken.symbol,
            blockchainName: topToken.networkName
        )
    }

    func sheetData(for experimentVariant: String?) -> YieldModePromoSheetData? {
        switch experimentVariant.flatMap(ExperimentArm.init(rawValue:)) {
        case .userMaxApy:
            candidateData
        case .globalMaxApy:
            topData
        case nil:
            nil
        }
    }

    private static func shownApy(_ apy: Decimal) -> Decimal {
        apy.rounded(scale: Constants.apyFractionScale, roundingMode: .plain)
    }
}

// MARK: - Experiment arms

private extension YieldModePromoContent {
    enum ExperimentArm: String {
        case userMaxApy = "user_max_apy"
        case globalMaxApy = "global_max_apy"
    }
}

// MARK: - Constants

private extension YieldModePromoContent {
    enum Constants {
        static let apyFractionScale = 4
    }
}

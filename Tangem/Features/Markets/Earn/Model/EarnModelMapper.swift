//
//  EarnModelMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - EarnModelMapper

struct EarnModelMapper {
    private let iconBuilder: IconURLBuilder = .init()

    // MARK: - Implementation

    func mapToEarnTokenModel(from response: EarnDTO.List.Item) -> EarnTokenModel {
        let rateValue = Decimal(stringValue: response.apy) ?? 0
        let rateType: RateType = response.rewardType.lowercased() == Constants.apy ? .apy : .apr
        let earnType: EarnType = response.type.lowercased() == Constants.staking ? .staking : .yieldMode

        return EarnTokenModel(
            id: response.token.id,
            name: response.token.name,
            symbol: response.token.symbol,
            imageUrl: iconBuilder.tokenIconURL(id: response.token.id),
            networkId: response.networkId,
            networkName: response.networkId.capitalized,
            networkImageUrl: iconBuilder.tokenIconURL(id: response.networkId),
            contractAddress: response.token.address,
            decimalCount: response.token.decimalCount,
            rateValue: rateValue,
            rateType: rateType,
            earnType: earnType
        )
    }

    // Constants

    private enum Constants {
        static let apy = "apy"
        static let staking = "staking"
    }
}

//
//  TokenFeeFixture.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
@testable import Tangem

enum TokenFeeFixture {
    static func make(
        value: Decimal?,
        blockchain: Blockchain = .ethereum(testnet: false),
        option: FeeOption = .market
    ) -> TokenFee {
        let loadingResult: LoadingResult<BSDKFee, any Error> = value.map {
            .success(BSDKFee(BSDKAmount(with: blockchain, value: $0)))
        } ?? .loading

        return TokenFee(
            option: option,
            tokenItem: .blockchain(.init(blockchain, derivationPath: nil)),
            value: loadingResult
        )
    }
}

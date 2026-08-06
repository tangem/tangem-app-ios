//
//  ExpressCurrencyTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("ExpressCurrency creation from an optional network and contract address")
struct ExpressCurrencyTests {
    @Test("A missing network means the currency can't be created")
    func missingNetworkPreventsCurrencyCreation() {
        #expect(ExpressCurrency(network: nil, contractAddress: Constants.tetherContractAddress) == nil)
        #expect(ExpressCurrency(network: nil, contractAddress: nil) == nil)
    }

    @Test("A missing contract address means the native coin")
    func missingContractAddressMeansTheNativeCoin() {
        let currency = ExpressCurrency(network: Constants.network, contractAddress: nil)

        #expect(currency == ExpressCurrency(contractAddress: ExpressConstants.coinContractAddress, network: Constants.network))
    }

    @Test("Both fields are used as is when present")
    func bothFieldsAreUsedAsIsWhenPresent() {
        let currency = ExpressCurrency(network: Constants.network, contractAddress: Constants.tetherContractAddress)

        #expect(currency == ExpressCurrency(contractAddress: Constants.tetherContractAddress, network: Constants.network))
    }
}

// MARK: - Constants

private extension ExpressCurrencyTests {
    enum Constants {
        static let network = "ethereum"
        static let tetherContractAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    }
}

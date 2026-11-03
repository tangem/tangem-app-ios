//
//  YieldTransactionFeeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Yield transaction fee")
struct YieldTransactionFeeTests {
    @Test("Deploy fee lists the deploy, approve and enter calls in sending order")
    func deployFeeKeepsCallOrder() throws {
        let fee = try DeployEnterFee(fees: makeFees(gasLimits: [300_000, 50_000, 200_000]))

        #expect(gasLimits(of: fee) == [300_000, 50_000, 200_000])
    }

    @Test("Init fee without an enter call lists only the init and approve calls")
    func initFeeWithoutEnter() throws {
        let fee = try InitEnterFee(fees: makeFees(gasLimits: [150_000, 50_000]), newImplementationAddress: nil)

        #expect(gasLimits(of: fee) == [150_000, 50_000])
    }

    @Test("Reactivate fee skips the approve call when no permission is required")
    func reactivateFeeWithoutApprove() throws {
        let fee = try ReactivateEnterFee(
            fees: makeFees(gasLimits: [100_000, 200_000]),
            isEnterAvailable: true,
            isPermissionRequired: false,
            newImplementationAddress: nil
        )

        #expect(gasLimits(of: fee) == [100_000, 200_000])
    }

    @Test("Exit fee lists its single call")
    func exitFeeHasSingleCall() throws {
        let fee = try ExitFee(fees: makeFees(gasLimits: [120_000]))

        #expect(gasLimits(of: fee) == [120_000])
    }
}

// MARK: - Helpers

private extension YieldTransactionFeeTests {
    func makeFees(gasLimits: [BigUInt]) -> [Fee] {
        gasLimits.map { gasLimit in
            Fee(
                Amount(with: .ethereum(testnet: false), type: .coin, value: 0.001),
                parameters: EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: 1, priorityFee: 1)
            )
        }
    }

    func gasLimits(of fee: YieldTransactionFee) -> [BigUInt] {
        fee.transactionFees.compactMap { ($0.parameters as? EthereumFeeParameters)?.gasLimit }
    }
}

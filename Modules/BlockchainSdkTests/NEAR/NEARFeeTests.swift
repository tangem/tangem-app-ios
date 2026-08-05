//
//  NEARFeeTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// NEAR takes the gas of the receipts a transaction produces upfront, at a price ten times higher than the one that
/// gas is eventually burnt at, and refunds the difference. The whole amount has to be available when the transaction
/// is validated, so the fee has to cover it, which is what these tests are about.
struct NEARFeeTests {
    private let blockchain: BlockchainSdk.Blockchain = .near(curve: .ed25519_slip0010, testnet: false)

    /// The gas price on mainnet sits at its lowest possible value, ten times lower than the price
    /// the gas of the receipts is bought at.
    private let gasPrice = Decimal(100_000_000)

    @Test("The protocol config is read from the response the mainnet actually returns")
    func protocolConfigIsReadFromResponse() throws {
        let protocolConfig = try makeMainnetProtocolConfig()

        #expect(protocolConfig.minGasPurchasePrice == Decimal(1_000_000_000))
        #expect(protocolConfig.pessimisticGasPriceInflationRatio == 1)
        #expect(protocolConfig.storageAmountPerByte == Decimal(string: "10000000000000000000"))
        #expect(protocolConfig.senderIsNotReceiver.cumulativeBasicSendCost == Decimal(223_182_562_500))
        #expect(protocolConfig.senderIsNotReceiver.cumulativeBasicExecutionCost == Decimal(223_182_562_500))
        #expect(protocolConfig.senderIsNotReceiver.cumulativeAdditionalSendCost == Decimal(601_765_125_000))
        #expect(protocolConfig.senderIsNotReceiver.cumulativeAdditionalExecutionCost == Decimal(7_301_765_125_000))
    }

    /// The transfer that proved the fee on the mainnet: the whole balance of one of our accounts sent to an account
    /// with an implicit ID that didn't exist yet, so the transfer had to create it, which makes it the costliest
    /// transfer there is. The network locked 0.007607442456250000 NEAR, of which it burnt 0.007114989537500000
    /// (0.00628 NEAR of that being the charge for creating the account) and refunded the rest back.
    @Test("The maximum amount left by the fee is the amount the mainnet accepted")
    func maximumAmountMatchesTheAcceptedTransfer() throws {
        let feeCalculator = try makeFeeCalculator()

        let availableToSend = try #require(Decimal(string: "2.738884504301829401088928"))
        let acceptedAmount = try #require(Decimal(string: "2.731277061845579401088928"))
        let amountLockedByTheNetwork = try #require(Decimal(string: "0.00760744245625"))

        let fee = feeCalculator.calculateFee(
            source: Constants.source,
            destination: Constants.implicitDestination
        )

        #expect(fee == amountLockedByTheNetwork)
        #expect(availableToSend - fee == acceptedAmount)
    }

    /// Only an account with an implicit ID has to be created by [REDACTED_AUTHOR]
    /// that creation. A transfer to an account that already has a name costs the transfer itself and nothing else.
    @Test("A transfer to a named account is not charged for creating an account")
    func transferToNamedAccountIsNotChargedForCreatingAnAccount() throws {
        let protocolConfig = try makeMainnetProtocolConfig()
        let feeCalculator = try makeFeeCalculator()

        let feeOfNamedDestination = feeCalculator.calculateFee(
            source: Constants.source,
            destination: "example.near"
        )
        let feeOfImplicitDestination = feeCalculator.calculateFee(
            source: Constants.source,
            destination: Constants.implicitDestination
        )

        let costs = protocolConfig.senderIsNotReceiver
        let accountCreationCost = (costs.cumulativeAdditionalSendCost * gasPrice
            + costs.cumulativeAdditionalExecutionCost * protocolConfig.minGasPurchasePrice)
            / blockchain.decimalValue

        #expect(feeOfNamedDestination == Decimal(string: "0.00024550081875"))
        #expect(feeOfImplicitDestination - feeOfNamedDestination == accountCreationCost)
    }

    /// The network used to raise the price of a receipt by 3% for every block the receipt has to travel, and
    /// publishes the ratio it raises it by. The ratio is one today, but bringing it back has to raise the price
    /// of the execution part alone: the send part is burnt at the price of the block the transaction lands in.
    @Test("Raising the ratio raises the price of the execution part and leaves the send part alone")
    func inflationRatioRaisesTheExecutionPartAlone() throws {
        let raisedRatio = try makeFeeCalculator(inflationRatio: (103, 100))
        let currentRatio = try makeFeeCalculator(inflationRatio: (1, 1))

        let sendPart = try #require(Decimal(string: "0.0000824947687500"))
        let executionPart = try #require(Decimal(string: "0.0075249476875000"))

        let feeWithCurrentRatio = currentRatio.calculateFee(
            source: Constants.source,
            destination: Constants.implicitDestination
        )
        let feeWithRaisedRatio = raisedRatio.calculateFee(
            source: Constants.source,
            destination: Constants.implicitDestination
        )

        #expect(feeWithCurrentRatio == sendPart + executionPart)
        #expect(feeWithRaisedRatio == sendPart + executionPart * Decimal(string: "1.03")!)
    }

    /// A transfer to the account of the sender is executed in the same block, so its receipt travels no blocks
    /// and its price isn't raised even when the ratio is above one.
    @Test("Raising the ratio doesn't touch a transfer of the sender to their own account")
    func inflationRatioDoesNotTouchATransferToSelf() throws {
        let raisedRatio = try makeFeeCalculator(inflationRatio: (103, 100))
        let currentRatio = try makeFeeCalculator(inflationRatio: (1, 1))

        let feeWithCurrentRatio = currentRatio.calculateFee(source: Constants.source, destination: Constants.source)
        let feeWithRaisedRatio = raisedRatio.calculateFee(source: Constants.source, destination: Constants.source)

        #expect(feeWithRaisedRatio == feeWithCurrentRatio)
    }

    // MARK: - Helpers

    private func makeFeeCalculator(inflationRatio: (numerator: Int, denominator: Int) = (1, 1)) throws -> NEARFeeCalculator {
        return NEARFeeCalculator(
            protocolConfig: try makeMainnetProtocolConfig(inflationRatio: inflationRatio),
            gasPrice: gasPrice,
            decimalValue: blockchain.decimalValue
        )
    }

    /// The fields of an `EXPERIMENTAL_protocol_config` response of the mainnet that we read, kept verbatim.
    private func makeMainnetProtocolConfig(
        inflationRatio: (numerator: Int, denominator: Int) = (1, 1)
    ) throws -> NEARProtocolConfig {
        let json = Data(
            """
            {
              "runtime_config": {
                "storage_amount_per_byte": "10000000000000000000",
                "min_gas_purchase_price": "1000000000",
                "transaction_costs": {
                  "pessimistic_gas_price_inflation_ratio": [\(inflationRatio.numerator), \(inflationRatio.denominator)],
                  "action_receipt_creation_config": {
                    "send_sir": 108059500000,
                    "send_not_sir": 108059500000,
                    "execution": 108059500000
                  },
                  "action_creation_config": {
                    "transfer_cost": {
                      "send_sir": 115123062500,
                      "send_not_sir": 115123062500,
                      "execution": 115123062500
                    },
                    "create_account_cost": {
                      "send_sir": 500000000000,
                      "send_not_sir": 500000000000,
                      "execution": 7200000000000
                    },
                    "add_key_cost": {
                      "full_access_cost": {
                        "send_sir": 101765125000,
                        "send_not_sir": 101765125000,
                        "execution": 101765125000
                      }
                    }
                  }
                }
              }
            }
            """.utf8
        )

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return NEARProtocolConfig(from: try decoder.decode(NEARNetworkResult.ProtocolConfig.self, from: json))
    }
}

// MARK: - Constants

private extension NEARFeeTests {
    enum Constants {
        static let source = "57a3ce28be219954dba12854619dde088344f5f37f1ac6641384f3a770ac4b28"
        static let implicitDestination = "1e21022a69a87b83ed57fa140bd04d40f68aadbf13779290f5b29ff738f47fd7"
    }
}

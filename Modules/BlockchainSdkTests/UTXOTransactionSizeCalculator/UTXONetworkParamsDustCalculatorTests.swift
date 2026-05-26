//
//  UTXONetworkParamsDustCalculatorTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Covers every `UTXONetworkParamsDustCalculator` strategy plus
/// `CommonUTXOTransactionSizeCalculator.dust(type:)`, which proves the
/// outputSize threading from caller down to strategy works.
class UTXONetworkParamsDustCalculatorTests {
    @Test(arguments: Self.cases)
    func dust(_ testCase: DustCase) {
        #expect(testCase.calculate() == testCase.expected, "\(testCase.label)")
    }

    struct DustCase {
        let label: String
        let calculate: () -> Int
        let expected: Int
    }

    private static let cases: [DustCase] = [
        // MARK: - Bitcoin family, floor branch (threshold < 294/546)

        // outputSize for each script type comes from CommonUTXOTransactionSizeCalculator.outputSize:
        // p2pk=44, p2pkh=34, p2sh=32, p2wpkh=31, p2wsh=43, p2tr=43.
        DustCase(
            label: "Bitcoin fee=3000 / p2pkh — 34*3000/1000=102, floor 546",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 3000).dust(outputSize: 34, type: .p2pkh) },
            expected: 546
        ),
        DustCase(
            label: "Bitcoin fee=3000 / p2wpkh — 31*3000/1000=93, witness floor 294",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 3000).dust(outputSize: 31, type: .p2wpkh) },
            expected: 294
        ),
        DustCase(
            label: "Bitcoin fee=3000 / p2sh — 32*3000/1000=96, floor 546",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 3000).dust(outputSize: 32, type: .p2sh) },
            expected: 546
        ),
        DustCase(
            label: "Bitcoin fee=3000 / p2tr — 43*3000/1000=129, witness floor 294",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 3000).dust(outputSize: 43, type: .p2tr) },
            expected: 294
        ),
        DustCase(
            label: "Bitcoin fee=1000 (BCH/DASH testnet) / p2pkh — 34*1000/1000=34, floor 546",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 1000).dust(outputSize: 34, type: .p2pkh) },
            expected: 546
        ),

        // MARK: - Bitcoin family, formula branch (threshold > 294/546)

        DustCase(
            label: "Bitcoin fee=20000 / p2pkh — 34*20000/1000=680, beats floor 546",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 20_000).dust(outputSize: 34, type: .p2pkh) },
            expected: 680
        ),
        DustCase(
            label: "Bitcoin fee=20000 / p2wpkh — 31*20000/1000=620, beats witness floor 294",
            calculate: { BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 20_000).dust(outputSize: 31, type: .p2wpkh) },
            expected: 620
        ),

        // MARK: - Dogecoin/Pepecoin — fixed 100_000, outputSize/type ignored

        DustCase(
            label: "Dogecoin / outputSize=0 p2pkh — constant 100_000",
            calculate: { DogecoinUTXONetworkParamsDustCalculator().dust(outputSize: 0, type: .p2pkh) },
            expected: 100_000
        ),
        DustCase(
            label: "Dogecoin / outputSize=999_999 p2tr — constant 100_000 (ignores params)",
            calculate: { DogecoinUTXONetworkParamsDustCalculator().dust(outputSize: 999_999, type: .p2tr) },
            expected: 100_000
        ),
        DustCase(
            label: "Pepecoin / outputSize=0 p2pkh — constant 100_000",
            calculate: { PepecoinUTXONetworkParamsDustCalculator().dust(outputSize: 0, type: .p2pkh) },
            expected: 100_000
        ),
        DustCase(
            label: "Pepecoin / outputSize=999_999 p2wpkh — constant 100_000 (ignores params)",
            calculate: { PepecoinUTXONetworkParamsDustCalculator().dust(outputSize: 999_999, type: .p2wpkh) },
            expected: 100_000
        ),

        // MARK: - Kaspa — fixed 20_000_000, outputSize/type ignored

        DustCase(
            label: "Kaspa / outputSize=0 p2pkh — KaspaTransactionBuilder.dustValue",
            calculate: { KaspaUTXONetworkParamsDustCalculator().dust(outputSize: 0, type: .p2pkh) },
            expected: KaspaTransactionBuilder.dustValue
        ),
        DustCase(
            label: "Kaspa / outputSize=999_999 p2wsh — KaspaTransactionBuilder.dustValue (ignores params)",
            calculate: { KaspaUTXONetworkParamsDustCalculator().dust(outputSize: 999_999, type: .p2wsh) },
            expected: KaspaTransactionBuilder.dustValue
        ),

        // MARK: - CommonUTXOTransactionSizeCalculator end-to-end

        // Proves the caller computes outputSize correctly and threads it through.

        DustCase(
            label: "Common(BitcoinNetworkParams mainnet) / p2pkh",
            calculate: { CommonUTXOTransactionSizeCalculator(network: BitcoinNetworkParams()).dust(type: .p2pkh) },
            expected: 546
        ),
        DustCase(
            label: "Common(BitcoinNetworkParams mainnet) / p2wpkh",
            calculate: { CommonUTXOTransactionSizeCalculator(network: BitcoinNetworkParams()).dust(type: .p2wpkh) },
            expected: 294
        ),
        DustCase(
            label: "Common(DogecoinNetworkParams) / p2pkh — strategy returns 100_000 regardless",
            calculate: { CommonUTXOTransactionSizeCalculator(network: DogecoinNetworkParams()).dust(type: .p2pkh) },
            expected: 100_000
        ),
        DustCase(
            label: "Common(PepecoinMainnetNetworkParams) / p2pkh — strategy returns 100_000 regardless",
            calculate: { CommonUTXOTransactionSizeCalculator(network: PepecoinMainnetNetworkParams()).dust(type: .p2pkh) },
            expected: 100_000
        ),
    ]
}

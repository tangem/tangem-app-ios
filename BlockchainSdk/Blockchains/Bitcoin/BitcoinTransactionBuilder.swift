//
//  BitcoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore
import WalletCore

class BitcoinTransactionBuilder {
    private let bitcoinManager: BitcoinManager
    private let unspentOutputManager: UnspentOutputManager

    private(set) var changeScript: Data?
    private let walletScripts: [BitcoinScript]

    init(bitcoinManager: BitcoinManager, unspentOutputManager: UnspentOutputManager, addresses: [Address]) {
        self.bitcoinManager = bitcoinManager
        self.unspentOutputManager = unspentOutputManager

        let scriptAddresses = addresses.compactMap { $0 as? BitcoinScriptAddress }
        let scripts = scriptAddresses.map { $0.script }
        let defaultScriptData = scriptAddresses
            .first(where: { $0.type == .default })
            .map { $0.script.data }

        walletScripts = scripts
        changeScript = defaultScriptData?.sha256()
    }

    func fee(amount: Decimal, destination: String?, feeRate: Int) throws -> Decimal {
        let outputs = try unspentOutputManager.selectOutputs(amount: amount.uint64Value, fee: .calculate(feeRate: UInt64(feeRate)))
        fillBitcoinManager(outputs: outputs)

        return bitcoinManager.fee(for: amount, address: destination, feeRate: feeRate, senderPay: false, changeScript: nil, sequence: .max)
    }

    func buildForSign(transaction: Transaction, sequence: Int?, sortType: TransactionDataSortType = .bip69) throws -> [Data] {
        guard let parameters = transaction.fee.parameters as? BitcoinFeeParameters else {
            throw WalletError.failedToBuildTx
        }

        let amount = transaction.amount.asSmallest().value
        let fee = transaction.fee.amount.asSmallest().value
        let outputs = try unspentOutputManager.selectOutputs(amount: amount.uint64Value, fee: .exactly(fee: fee.uint64Value))
        fillBitcoinManager(outputs: outputs)

        let hashes = try bitcoinManager.buildForSign(
            target: transaction.destinationAddress,
            amount: transaction.amount.value,
            feeRate: parameters.rate,
            sortType: sortType,
            changeScript: changeScript,
            sequence: sequence
        )
        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [Data], sequence: Int?, sortType: TransactionDataSortType = .bip69) throws -> Data {
        guard let signatures = convertToDER(signatures),
              let parameters = transaction.fee.parameters as? BitcoinFeeParameters else {
            throw WalletError.failedToBuildTx
        }

        let amount = transaction.amount.asSmallest().value
        let fee = transaction.fee.amount.asSmallest().value
        let outputs = try unspentOutputManager.selectOutputs(amount: amount.uint64Value, fee: .exactly(fee: fee.uint64Value))
        fillBitcoinManager(outputs: outputs)

        return try bitcoinManager.buildForSend(
            target: transaction.destinationAddress,
            amount: transaction.amount.value,
            feeRate: parameters.rate,
            sortType: sortType,
            derSignatures: signatures,
            changeScript: changeScript,
            sequence: sequence
        )
    }

    private func fillBitcoinManager(outputs: [ScriptUnspentOutput]) {
        let utxos = outputs.map {
            UtxoDTO(
                hash: Data($0.output.hash.reversed()),
                index: $0.output.index,
                value: Int($0.output.amount),
                script: $0.script
            )
        }

        let spendingScripts: [Script] = walletScripts.compactMap { script in
            let chunks = script.chunks.enumerated().map { index, chunk in
                Chunk(scriptData: script.data, index: index, payloadRange: chunk.range)
            }
            return Script(with: script.data, chunks: chunks)
        }

        bitcoinManager.fillBlockchainData(unspentOutputs: utxos, spendingScripts: spendingScripts)
    }

    private func convertToDER(_ signatures: [Data]) -> [Data]? {
        var derSigs = [Data]()

        let utils = Secp256k1Utils()
        for signature in signatures {
            guard let signDer = try? utils.serializeDer(signature) else {
                return nil
            }

            derSigs.append(signDer)
        }

        return derSigs
    }
}

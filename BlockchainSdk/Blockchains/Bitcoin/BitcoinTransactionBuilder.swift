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

class BitcoinTransactionBuilder {
    private let bitcoinManager: BitcoinManager
    private let unspentOutputManager: UnspentOutputManager

    /// Need only for double public key (Twin cards)
    private let multisigParameters: MultisigParameters?

    init(bitcoinManager: BitcoinManager, unspentOutputManager: UnspentOutputManager, addresses: [Address]) {
        self.bitcoinManager = bitcoinManager
        self.unspentOutputManager = unspentOutputManager

        multisigParameters = .init(addresses: addresses)
    }

    func fee(amount: Amount, address: String, feeRate: Int) throws -> Int {
        let satoshi = amount.asSmallest().value.intValue()
        let preImage = try unspentOutputManager.preImage(amount: satoshi, feeRate: feeRate, destination: address)
        return preImage.fee
    }

    func buildForSign(transaction: Transaction, sequence: Int?, sortType: TransactionDataSortType = .bip69) throws -> [Data] {
        guard let parameters = transaction.fee.parameters as? BitcoinFeeParameters else {
            throw Error.noBitcoinFeeParameters
        }

        let preImage = try unspentOutputManager.preImage(transaction: transaction)
        fillBitcoinManager(outputs: preImage.inputs)

        let hashes = try bitcoinManager.buildForSign(
            target: transaction.destinationAddress,
            amount: transaction.amount.value,
            feeRate: parameters.rate,
            sortType: sortType,
            changeScript: multisigParameters?.changeScript,
            sequence: sequence
        )

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [Data], sequence: Int?, sortType: TransactionDataSortType = .bip69) throws -> Data {
        guard let parameters = transaction.fee.parameters as? BitcoinFeeParameters else {
            throw Error.noBitcoinFeeParameters
        }

        let preImage = try unspentOutputManager.preImage(transaction: transaction)
        fillBitcoinManager(outputs: preImage.inputs)

        let signatures = try convertToDER(signatures)
        return try bitcoinManager.buildForSend(
            target: transaction.destinationAddress,
            amount: transaction.amount.value,
            feeRate: parameters.rate,
            sortType: sortType,
            derSignatures: signatures,
            changeScript: multisigParameters?.changeScript,
            sequence: sequence
        )
    }

    private func mapToUtxoDTO(output: ScriptUnspentOutput) -> UtxoDTO {
        UtxoDTO(
            hash: Data(output.hash.reversed()),
            index: output.index,
            value: Int(output.amount),
            script: output.script.data
        )
    }

    private func fillBitcoinManager(outputs: [ScriptUnspentOutput]) {
        let utxos = outputs.map { mapToUtxoDTO(output: $0) }
        let spendingScripts: [Script]? = multisigParameters?.walletScripts.compactMap { script in
            let chunks = script.chunks.enumerated().map { index, chunk in
                Chunk(scriptData: script.data, index: index, payloadRange: chunk.range)
            }
            return Script(with: script.data, chunks: chunks)
        }

        bitcoinManager.fillBlockchainData(unspentOutputs: utxos, spendingScripts: spendingScripts ?? [])
    }

    private func convertToDER(_ signatures: [Data]) throws -> [Data] {
        let utils = Secp256k1Utils()
        return try signatures.compactMap {
            try utils.serializeDer($0)
        }
    }
}

extension BitcoinTransactionBuilder {
    enum Error: LocalizedError {
        case noBitcoinFeeParameters
    }
}

struct MultisigParameters {
    let walletScripts: [BitcoinScript]
    let changeScript: Data?

    init(addresses: [Address]) {
        let scriptAddresses = addresses.compactMap { $0 as? BitcoinScriptAddress }
        let scripts = scriptAddresses.map { $0.script }
        let defaultScriptData = scriptAddresses
            .first(where: { $0.type == .default })
            .map { $0.script.data }

        walletScripts = scripts
        changeScript = defaultScriptData?.sha256()
    }
}

//
//  RadiantTransactionUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import TangemFoundation

struct RadiantScriptUtils {
    /// Default implementation BitcoinCash signed scripts
    func buildSignedScripts(signatures: [Data], publicKey: Data) throws -> [Data] {
        var scripts: [Data] = .init()
        scripts.reserveCapacity(signatures.count)
        for signature in signatures {
            let signDer = try Secp256k1Signature(with: signature).serializeDer()
            var script = Data()
            script.append((signDer.count + 1).byte)
            script.append(contentsOf: signDer)
            script.append(UInt8(0x41))
            script.append(UInt8(0x21))
            script.append(contentsOf: publicKey)
            scripts.append(script)
        }

        return scripts
    }

    func writePrevoutHash(_ unspents: [RadiantTransactionBuilder.UnspentOutput], into txToSign: inout Data) {
        let prevouts = unspents
            .map { Data($0.hash.reversed()) + $0.index.bytes4LE }
            .joined()

        let hashPrevouts = Data(prevouts).getDoubleSHA256()
        txToSign.append(contentsOf: hashPrevouts)
    }

    func writeSequenceHash(_ unspents: [RadiantTransactionBuilder.UnspentOutput], into txToSign: inout Data) {
        let sequence = Data(repeating: UInt8(0xFF), count: 4 * unspents.count)
        let hashSequence = sequence.getDoubleSHA256()
        txToSign.append(contentsOf: hashSequence)
    }

    /// Default BitcoinCash implementation for set hash output values transaction data
    func writeHashOutput(
        outputs: [RadiantTransactionBuilder.TransactionOutput],
        into txToSign: inout Data
    ) {
        var bytes = Data()

        outputs.forEach { output in
            bytes.append(output.amount.bytes8LE)
            bytes.append(output.lockingScript.data.count.byte)
            bytes.append(contentsOf: output.lockingScript.data)
        }

        let hashOutput = bytes.getDoubleSHA256()
        // Write bytes
        txToSign.append(contentsOf: hashOutput)
    }

    /// Specify for radiant blockchain
    /// See comment here for how it works https://github.com/RadiantBlockchain/radiant-node/blob/master/src/primitives/transaction.h#L493
    /// Since your transactions won't contain pushrefs, it will be very simple, like the commit I sent above
    func writeHashOutputHashes(
        outputs: [RadiantTransactionBuilder.TransactionOutput],
        into txToSign: inout Data
    ) {
        let zeroRefHash = [UInt8](repeating: 0, count: 32)
        var bytes = Data()

        outputs.forEach { output in
            bytes.append(output.amount.bytes8LE)

            let scriptHash = output.lockingScript.data.getDoubleSHA256()
            bytes.append(contentsOf: scriptHash)

            // Total refs
            bytes.append(0.bytes4LE)

            // Add zeroRef 32 bytes
            bytes.append(contentsOf: zeroRefHash)
        }

        let hashOutputHash = bytes.getDoubleSHA256()
        txToSign.append(contentsOf: hashOutputHash)
    }
}

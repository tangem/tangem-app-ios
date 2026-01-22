//
//  BitcoinPsbtTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BitcoinDevKit
import TangemSdk
import Testing
import WalletCore
@testable import BlockchainSdk

struct BitcoinPsbtTests {
    @Test
    func applySignaturesFinalizesPsbt() throws {
        let fixture = PsbtTestCase.Segwit.singleInputSingleOutput.fixture
        let hashes = try BitcoinPsbtSigningBuilder.hashesToSign(
            psbtBase64: fixture.psbtBase64,
            signInputs: [.init(index: 0)] // sign the only input
        )
        let hashToSign = try #require(hashes.first)
        let signature = try #require(fixture.privateKey.sign(digest: hashToSign, curve: .secp256k1))
        let signatureInfo = SignatureInfo(
            signature: signature.prefix(64),
            publicKey: fixture.publicKey,
            hash: hashToSign
        )

        let originalMaps = try PsbtKeyValueMap(
            data: try #require(Data(base64Encoded: fixture.psbtBase64)),
            inputCount: fixture.inputCount,
            outputCount: fixture.outputCount
        )

        let signedPsbtBase64 = try BitcoinPsbtSigningBuilder.applySignaturesAndFinalize(
            psbtBase64: fixture.psbtBase64,
            signInputs: [.init(index: 0)],
            signatures: [signatureInfo],
            publicKey: fixture.publicKey
        )

        let signedMaps = try PsbtKeyValueMap(
            data: try #require(Data(base64Encoded: signedPsbtBase64)),
            inputCount: fixture.inputCount,
            outputCount: fixture.outputCount
        )

        #expect(signedPsbtBase64 != fixture.psbtBase64)
        #expect(signedMaps.inputMaps[0].count > originalMaps.inputMaps[0].count)
    }

    @Test
    func produceValidPsbtTransaction() throws {
        let fixture = PsbtTestCase.Segwit.singleInputSingleOutput.fixture
        let psbtBase64 = fixture.psbtBase64 // input PSBT base64

        let hashes = try BitcoinPsbtSigningBuilder.hashesToSign(
            psbtBase64: psbtBase64,
            signInputs: [.init(index: 0)] // sign the only input
        )
        let hashToSign = try #require(hashes.first)
        let signature = try #require(fixture.privateKey.sign(digest: hashToSign, curve: .secp256k1))
        let signatureInfo = SignatureInfo(
            signature: signature.prefix(64),
            publicKey: fixture.publicKey,
            hash: hashToSign
        )

        let signedPsbtBase64 = try BitcoinPsbtSigningBuilder.applySignaturesAndFinalize(
            psbtBase64: psbtBase64,
            signInputs: [.init(index: 0)],
            signatures: [signatureInfo],
            publicKey: fixture.publicKey
        )

        let extractedTx = try Psbt(psbtBase64: signedPsbtBase64).extractTx().serialize()

        let inputScript = UTXOLockingScript(
            data: OpCodeUtils.p2wpkh(version: 0, data: fixture.pubKeyHash),
            type: .p2wpkh,
            spendable: .publicKey(fixture.publicKey)
        )
        let input = ScriptUnspentOutput(
            output: UnspentOutput(
                blockId: 1,
                txId: fixture.txInputs[0].txid.hex(),
                index: Int(fixture.txInputs[0].vout),
                amount: fixture.utxoValue
            ),
            script: inputScript
        )
        let outputScript = UTXOLockingScript(
            data: fixture.txOutputs[0].scriptPubKey,
            type: .p2wpkh,
            spendable: .none
        )
        let preImage = PreImageTransaction(
            inputs: [input],
            outputs: [.destination(outputScript, value: Int(fixture.txOutputs[0].value))],
            fee: 0
        )
        let transaction = Transaction(
            amount: Amount(with: .bitcoin(testnet: false), value: .init(stringValue: "0.001")!),
            fee: Fee(Amount(with: .bitcoin(testnet: false), value: .init(stringValue: "0")!)),
            sourceAddress: "source",
            destinationAddress: "destination",
            changeAddress: "change"
        )

        let serializer = CommonUTXOTransactionSerializer(
            version: fixture.version,
            sequence: .final,
            signHashType: .bitcoinAll
        )
        let expectedSignatureInfo = SignatureInfo(
            signature: try signatureInfo.der(),
            publicKey: fixture.publicKey,
            hash: hashToSign
        )
        let expectedTx = try serializer.compile(
            transaction: (transaction: transaction, preImage: preImage),
            signatures: [expectedSignatureInfo]
        )

        #expect(extractedTx == expectedTx)
    }

    @Test(arguments: [PsbtTestCase.Segwit.singleInputSingleOutput])
    func hashesToSign_segwitInput_matchesSighashBuilder(testCase: PsbtTestCase.Segwit) throws {
        let fixture = testCase.fixture
        let scriptCode = OpCodeUtils.p2pkh(data: fixture.pubKeyHash)

        let hashes = try BitcoinPsbtSigningBuilder.hashesToSign(
            psbtBase64: fixture.psbtBase64,
            signInputs: [.init(index: 0)] // sign the only input
        )
        let expectedHash = try BitcoinSighashBuilder.segwitV0SighashAll(
            version: fixture.version,
            lockTime: fixture.lockTime,
            inputs: fixture.txInputs,
            outputs: fixture.txOutputs,
            inputIndex: 0,
            scriptCode: scriptCode,
            value: fixture.utxoValue
        )

        #expect(hashes == [expectedHash])
    }

    @Test
    func hashesToSign_invalidBase64_throws() {
        #expect(throws: (any Error).self) {
            _ = try BitcoinPsbtSigningBuilder.hashesToSign(
                psbtBase64: "not_base64", // invalid base64 input
                signInputs: [.init(index: 0)]
            )
        }
    }

    @Test
    func applySignatures_wrongSignaturesCount() throws {
        let fixture = PsbtTestCase.Segwit.singleInputSingleOutput.fixture
        let hashToSign = try BitcoinPsbtSigningBuilder.hashesToSign(
            psbtBase64: fixture.psbtBase64,
            signInputs: [.init(index: 0)] // sign the only input
        )[0]
        let signature = try #require(fixture.privateKey.sign(digest: hashToSign, curve: .secp256k1))
        let signatureInfo = SignatureInfo(
            signature: signature.prefix(64),
            publicKey: fixture.publicKey,
            hash: hashToSign
        )

        #expect(throws: (any Error).self) {
            _ = try BitcoinPsbtSigningBuilder.applySignaturesAndFinalize(
                psbtBase64: fixture.psbtBase64,
                signInputs: [.init(index: 0), .init(index: 1)], // two inputs, only one signature
                signatures: [signatureInfo],
                publicKey: fixture.publicKey
            )
        }
    }
}

struct PsbtFixture {
    let psbtBase64: String
    let version: UInt32
    let lockTime: UInt32
    let inputCount: Int
    let outputCount: Int
    let txInputs: [BitcoinSighashBuilder.Input]
    let txOutputs: [BitcoinSighashBuilder.Output]
    let utxoValue: UInt64
    let pubKeyHash: Data
    let privateKey: WalletCore.PrivateKey
    let publicKey: Data
}

enum PsbtTestCase {
    struct Segwit {
        let name: Comment
        let fixture: PsbtFixture

        static let singleInputSingleOutput: Self = .init(
            name: "Single-input P2WPKH -> P2WPKH",
            fixture: {
                let privateKeyData = Data(hexString: "e120fc1ef9d193a851926ebd937c3985dc2c4e642fb3d0832317884d5f18f3b3") // deterministic secp256k1 key
                let privateKey = WalletCore.PrivateKey(data: privateKeyData)!
                let publicKey = privateKey.getPublicKeySecp256k1(compressed: true).data
                let pubKeyHash = RIPEMD160.hash(publicKey.sha256()) // HASH160(pubkey) for P2WPKH

                let utxoValue: UInt64 = 120_000 // 0.0012 BTC
                let utxoScript = OpCodeUtils.p2wpkh(version: 0, data: pubKeyHash) // v0 P2WPKH
                let witnessUtxo = PsbtTestBuilder.makeTxOut(value: utxoValue, scriptPubKey: utxoScript)

                let input = PsbtTestBuilder.TxInput(
                    txid: Data(repeating: 0x11, count: 32), // dummy txid (32 bytes)
                    vout: 0, // spend first output
                    sequence: 0xFFFF_FFFF // final
                )
                let outputScript = OpCodeUtils.p2wpkh(version: 0, data: Data(repeating: 0x22, count: 20)) // dummy pubkey hash
                let output = PsbtTestBuilder.TxOutput(value: 100_000, scriptPubKey: outputScript) // 0.001 BTC

                let version: UInt32 = 2 // v2 tx
                let lockTime: UInt32 = 0 // no locktime
                let unsignedTx = PsbtTestBuilder.makeUnsignedTransaction(
                    version: version,
                    lockTime: lockTime,
                    inputs: [input],
                    outputs: [output]
                )

                let psbtBase64 = PsbtTestBuilder.makePsbtBase64(
                    unsignedTx: unsignedTx,
                    witnessUtxo: witnessUtxo,
                    inputCount: 1,
                    outputCount: 1
                )

                return PsbtFixture(
                    psbtBase64: psbtBase64,
                    version: version,
                    lockTime: lockTime,
                    inputCount: 1,
                    outputCount: 1,
                    txInputs: [
                        BitcoinSighashBuilder.Input(txid: input.txid, vout: input.vout, sequence: input.sequence),
                    ],
                    txOutputs: [
                        BitcoinSighashBuilder.Output(value: output.value, scriptPubKey: output.scriptPubKey),
                    ],
                    utxoValue: utxoValue,
                    pubKeyHash: pubKeyHash,
                    privateKey: privateKey,
                    publicKey: publicKey
                )
            }()
        )
    }
}

private enum PsbtTestBuilder {
    struct TxInput {
        let txid: Data
        let vout: UInt32
        let sequence: UInt32
    }

    struct TxOutput {
        let value: UInt64
        let scriptPubKey: Data
    }

    static func makeUnsignedTransaction(
        version: UInt32,
        lockTime: UInt32,
        inputs: [TxInput],
        outputs: [TxOutput]
    ) -> Data {
        var data = Data()
        data.append(version.littleEndianData)
        data.append(VariantIntEncoder.encode(UInt64(inputs.count)))

        for input in inputs {
            data.append(input.txid)
            data.append(input.vout.littleEndianData)
            data.append(0x00) // empty scriptSig
            data.append(input.sequence.littleEndianData)
        }

        data.append(VariantIntEncoder.encode(UInt64(outputs.count)))

        for output in outputs {
            data.append(output.value.littleEndianData)
            data.append(VariantIntEncoder.encode(UInt64(output.scriptPubKey.count)))
            data.append(output.scriptPubKey)
        }

        data.append(lockTime.littleEndianData)
        return data
    }

    static func makeTxOut(value: UInt64, scriptPubKey: Data) -> Data {
        var data = Data()
        data.append(value.littleEndianData)
        data.append(VariantIntEncoder.encode(UInt64(scriptPubKey.count)))
        data.append(scriptPubKey)
        return data
    }

    static func makePsbtBase64(
        unsignedTx: Data,
        witnessUtxo: Data,
        inputCount: Int,
        outputCount: Int
    ) -> String {
        var data = Data([0x70, 0x73, 0x62, 0x74, 0xff]) // "psbt" + 0xff

        data.append(VariantIntEncoder.encode(1)) // key type length
        data.append(0x00) // PSBT_GLOBAL_UNSIGNED_TX
        data.append(VariantIntEncoder.encode(UInt64(unsignedTx.count)))
        data.append(unsignedTx)
        data.append(0x00) // end of global map

        for _ in 0 ..< inputCount {
            data.append(VariantIntEncoder.encode(1)) // key type length
            data.append(0x01) // PSBT_IN_WITNESS_UTXO
            data.append(VariantIntEncoder.encode(UInt64(witnessUtxo.count)))
            data.append(witnessUtxo)
            data.append(0x00) // end of input map
        }

        for _ in 0 ..< outputCount {
            data.append(0x00) // end of output map (empty)
        }

        return data.base64EncodedString()
    }
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var value = littleEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
}

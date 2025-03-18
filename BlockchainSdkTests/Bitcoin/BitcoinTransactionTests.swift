//
//  BitcoinTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import BitcoinCore
import TangemSdk
@testable import BlockchainSdk
import Testing

final class BitcoinTransactionTests {
    private let blockchain = Blockchain.bitcoin(testnet: false)
    private let networkParams = BitcoinNetwork.mainnet.networkParams
    private lazy var addressService = BitcoinAddressService(networkParams: networkParams)
    private let sizeTester = TransactionSizeTesterUtility()

    @Test
    func correctCoinTransaction() throws {
        let pubkey = Data(hex: "046DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D744A863B14DE2457D82BEE322416523E336530760C4533AEE980F4A4CDB9A98D")
        let compressedPubkey = try! Secp256k1Key(with: pubkey).compress()
        #expect(compressedPubkey != nil)

        let signature1 = Data(hex: "00325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B93C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B4")

        let signature2 = Data(hex: "ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A7247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B07")
        let sendValue = Decimal(0.4)
        let feeValue = Decimal(0.00004641)
        let destination = "bc1q67dmfccnax59247kshfkxcq6qr53wmwqfa4s28cupktj2amf5jus2j6qvt"

        let addresses = [
            try addressService.makeAddress(from: pubkey, type: .default),
            try addressService.makeAddress(from: pubkey, type: .legacy),
        ]

        let segwit = addresses.first(where: { $0.type == .default })!
        let manager = BitcoinManager(networkParams: networkParams, walletPublicKey: pubkey, compressedWalletPublicKey: compressedPubkey)
        let converter = SegWitBech32AddressConverter(prefix: networkParams.bech32PrefixPattern, scriptConverter: ScriptConverter())
        let seg: SegWitAddress = try! converter.convert(address: segwit.value) as! SegWitAddress
        XCTAssertEqual(seg.stringValue, segwit.value)
        let unspentOutputManager = prepareFilledUnspentOutputManager(for: [seg])
        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: manager, unspentOutputManager: unspentOutputManager, addresses: addresses)

        let amountToSend = Amount(with: blockchain, type: .coin, value: sendValue)
        let feeAmount = Amount(with: blockchain, type: .coin, value: feeValue)
        let fee = Fee(feeAmount, parameters: BitcoinFeeParameters(rate: 21))
        let transaction = Transaction(amount: amountToSend, fee: fee, sourceAddress: segwit.value, destinationAddress: destination, changeAddress: "")

        let expectedHashToSign1 = Data(hex: "8272779353EAD7848859916DFA4E6ED4DAA54989CA6258566D0FFEDEC2002400")
        let expectedHashToSign2 = Data(hex: "5624DB10BC172D5300C03EB50E3A1B2947CDCE4C89F483994DF07BB81EB97EA8")
        let expectedSignedTransaction = Data(hex: "01000000000102DF05DDAF1B9E0D7A36672DA32986499F5EC8B3946429D16E1CD6736CF4A3FECF0100000000FAFFFFFFEF0788C82E89047D926062A41C8500C4FE896069E95C37251D6B8CEED67A908B0000000000FAFFFFFF02005A620200000000220020D79BB4E313E9A85557D685D363601A00E9176DC04F6B051F1C0D97257769A4B9AF04B90000000000160014309A0C6EFA0DA7966D5C42DC5A928F6BAF0E47EF02463043021F325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B902203C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B40121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D02483045022100ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A02207247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B070121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D00000000")
        testTransaction(
            transaction,
            signatures: [signature1, signature2],
            txBuilder: txBuilder,
            sortType: .none,
            expectedHashes: [expectedHashToSign1, expectedHashToSign2],
            expectedSignedTransaction: expectedSignedTransaction
        )

        let expectedHashToSign1Sorted = Data(hex: "524AA09FDD0F8B414E2C66C650C9853C020963D56B84CE3049FDDD56869E5EEA")
        let expectedHashToSign2Sorted = Data(hex: "CA0F139AD25974812C294544229ECE7D3293B9E53680AC63B83B3BC1B2FC22BD")
        let expectedSignedSortedTransaction = Data(hex: "01000000000102EF0788C82E89047D926062A41C8500C4FE896069E95C37251D6B8CEED67A908B0000000000FAFFFFFFDF05DDAF1B9E0D7A36672DA32986499F5EC8B3946429D16E1CD6736CF4A3FECF0100000000FAFFFFFF02AF04B90000000000160014309A0C6EFA0DA7966D5C42DC5A928F6BAF0E47EF005A620200000000220020D79BB4E313E9A85557D685D363601A00E9176DC04F6B051F1C0D97257769A4B902463043021F325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B902203C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B40121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D02483045022100ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A02207247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B070121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D00000000")
        testTransaction(
            transaction,
            signatures: [signature1, signature2],
            txBuilder: txBuilder,
            sortType: .bip69,
            expectedHashes: [expectedHashToSign1Sorted, expectedHashToSign2Sorted],
            expectedSignedTransaction: expectedSignedSortedTransaction
        )
    }

    private func prepareFilledUnspentOutputManager(for addresses: [BitcoinCore.Address]) -> UnspentOutputManager {
        #expect(!addresses.isEmpty)
        let utxo1Script = try? ScriptBuilder.createOutputScriptData(for: addresses[0])
        #expect(utxo1Script != nil)
        #expect("0014309a0c6efa0da7966d5c42dc5a928f6baf0e47ef" == utxo1Script?.hexString.lowercased())
        let utxo2Script = try? ScriptBuilder.createOutputScriptData(for: addresses.count > 1 ? addresses[1] : addresses[0])
        #expect(utxo2Script != nil)
        #expect("0014309a0c6efa0da7966d5c42dc5a928f6baf0e47ef" == utxo2Script?.hexString.lowercased())

        let unspentOutputManager = CommonUnspentOutputManager()
        unspentOutputManager.update(
            outputs: [
                .init(
                    blockId: .random(),
                    hash: Data(hexString: "8b907ad6ee8c6b1d25375ce9696089fec400851ca46260927d04892ec88807ef"),
                    index: 0,
                    amount: 39920000
                ),
            ],
            for: utxo1Script
        )

        unspentOutputManager.update(
            outputs: [
                .init(
                    blockId: .random(),
                    hash: Data(hexString: "cffea3f46c73d61c6ed1296494b3c85e9f498629a32d67367a0d9e1bafdd05df"),
                    index: 1,
                    amount: 12210000
                ),
            ],
            for: utxo2Script
        )

        return unspentOutputManager
    }

    private func testTransaction(
        _ transaction: BlockchainSdk.Transaction,
        signatures: [Data],
        txBuilder: BitcoinTransactionBuilder,
        sortType: TransactionDataSortType,
        expectedHashes: [Data],
        expectedSignedTransaction: Data
    ) {
        let buildToSignResult = txBuilder.buildForSign(transaction: transaction, sequence: 4294967290, sortType: sortType)!
        sizeTester.testTxSizes(buildToSignResult)
        let signedTx = txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: 4294967290, sortType: sortType)

        #expect(buildToSignResult.map(\.hexString) == expectedHashes.map(\.hexString))
        #expect(signedTx?.hexString == expectedSignedTransaction.hexString)
    }
}

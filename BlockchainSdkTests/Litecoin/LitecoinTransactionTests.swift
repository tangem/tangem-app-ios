//
//  LitecoinTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import BitcoinCore
import TangemSdk
import Testing
@testable import BlockchainSdk

final class LitecoinTransactionTests {
    private let blockchain = Blockchain.litecoin
    private let networkParams = LitecoinNetworkParams()
    private let walletPublicKey = Data(
        hexString: "04AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EA"
    )

    private lazy var addressService = BitcoinAddressService(networkParams: networkParams)
    private lazy var bitcoinManager: BitcoinManager = {
        let compressedWalletPublicKey = try! Secp256k1Key(with: walletPublicKey).compress()
        return .init(networkParams: networkParams, walletPublicKey: walletPublicKey, compressedWalletPublicKey: compressedWalletPublicKey, bip: .bip44)
    }()

    @Test
    func unsortedOutputsTransaction() throws {
        // given
        let address = try addressService.makeAddress(from: walletPublicKey, type: .legacy)
        let unspentOutputManager = try prepareFilledUnspentOutputManager(address: address)
        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, unspentOutputManager: unspentOutputManager, addresses: [])
        let amountToSend = Amount(with: blockchain, type: .coin, value: 0.00015)
        let fee = Fee(Amount(with: blockchain, type: .coin, value: 0.00001752), parameters: BitcoinFeeParameters(rate: 4))
        let destination = "LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M"

        let signatures = [
            Data(hex: "F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB4E7C314437399CB915AA9580458DDC2440EA3E6121CC2D6B5F5C67232B5B60C54"),
            Data(hex: "B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE30105AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC"),
        ]

        let transaction = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        // when
        let hashes = try txBuilder.buildForSign(transaction: transaction, sequence: 4294967290, sortType: .none)
        let signedTx = try txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: 4294967290, sortType: .none)

        // then
        let expectedHashes = [
            Data(hex: "4E17896956F9B8AFCCD0B2BBF5AC50462508C0AC1485EB6580AF7CC9300E837E"),
            Data(hex: "E84A90E9E9DAE1EACAA2F12B79FF8824F868EA77C35272ADE0DFF8D2DAA8391E"),
        ]

        let expectedSignedTransaction = Data(hex: "0100000002AEED3F4EBDEFC373361387DD7E5D926311B934B3E48614428E3E32C11BFEACBC000000008B483045022100F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB40220183CEBBC8C66346EA556A7FBA7223DBAAC0AF6D49285C985CA0BEC5A1A8034ED014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFFFF863FEFC5EF29D4F33B13F969E88971A0EA0523FD913072DC50A1F8D7FB16FA000000008B483045022100B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE301022005AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFF02983A0000000000001976A9147E3618C4A80997D5F836FA17A10FCC17B4A9245188ACB00C0000000000001976A914CCD4649CDB4C9F8FDB54869CFF112A4E75FDA2BB88AC00000000")

        #expect(hashes == expectedHashes)
        #expect(signedTx == expectedSignedTransaction)
    }

    @Test
    func sortedOutputsTransaction() throws {
        // given
        let address = try addressService.makeAddress(from: walletPublicKey, type: .legacy)
        let unspentOutputManager = try prepareFilledUnspentOutputManager(address: address)
        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, unspentOutputManager: unspentOutputManager, addresses: [])
        let amountToSend = Amount(with: blockchain, type: .coin, value: 0.00015)
        let fee = Fee(Amount(with: blockchain, type: .coin, value: 0.00001752), parameters: BitcoinFeeParameters(rate: 4))
        let destination = "LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M"

        let signatures = [
            Data(hex: "F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB4E7C314437399CB915AA9580458DDC2440EA3E6121CC2D6B5F5C67232B5B60C54"),
            Data(hex: "B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE30105AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC"),
        ]

        let transaction = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        // when
        let hashes = try txBuilder.buildForSign(transaction: transaction, sequence: 4294967290, sortType: .bip69)
        let signedTx = try txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: 4294967290, sortType: .bip69)

        // then
        let expectedHashes = [
            Data(hex: "0eb63431fbe70eb30d8ef8d788c5a7971d1bbd319b54dd8252578f3f84311e2f"),
            Data(hex: "eb7b158f86c6fc825f199d7addcb0003e7c5474abe515f466cbd8c54daf4e123"),
        ]

        let expectedSignedTransaction = Data(hex: "0100000002AEED3F4EBDEFC373361387DD7E5D926311B934B3E48614428E3E32C11BFEACBC000000008B483045022100F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB40220183CEBBC8C66346EA556A7FBA7223DBAAC0AF6D49285C985CA0BEC5A1A8034ED014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFFFF863FEFC5EF29D4F33B13F969E88971A0EA0523FD913072DC50A1F8D7FB16FA000000008B483045022100B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE301022005AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFF02B00C0000000000001976A914CCD4649CDB4C9F8FDB54869CFF112A4E75FDA2BB88AC983A0000000000001976A9147E3618C4A80997D5F836FA17A10FCC17B4A9245188AC00000000")

        #expect(hashes == expectedHashes)
        #expect(signedTx == expectedSignedTransaction)
    }

    private func prepareFilledUnspentOutputManager(address: any BlockchainSdk.Address) throws -> UnspentOutputManager {
        let unspentOutputManager: UnspentOutputManager = .litecoin(address: address)
        let outputs = [
            UnspentOutput(
                blockId: .random(in: 1 ... 100_000),
                txId: "bcacfe1bc1323e8e421486e4b334b91163925d7edd87133673c3efbd4e3fedae",
                index: 0,
                amount: 10000
            ),
            UnspentOutput(
                blockId: .random(in: 1 ... 100_000),
                txId: "fa16fbd7f8a150dc723091fd2305eaa07189e869f9133bf3d429efc5ef3f86ff",
                index: 0,
                amount: 10000
            ),
        ]

        unspentOutputManager.update(outputs: outputs, for: address)
        return unspentOutputManager
    }
}

//
//  BitcoinTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import BitcoinCore
import TangemSdk
import Testing
@testable import BlockchainSdk

final class BitcoinTransactionTests {
    private let blockchain = Blockchain.bitcoin(testnet: false)
    private let networkParams = BitcoinNetworkParams()
    private let walletPublicKey = Data(
        hexString: "046DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D744A863B14DE2457D82BEE322416523E336530760C4533AEE980F4A4CDB9A98D"
    )

    private lazy var addressService = BitcoinAddressService(networkParams: networkParams)
    private lazy var bitcoinManager: BitcoinManager = {
        let compressedWalletPublicKey = try! Secp256k1Key(with: walletPublicKey).compress()
        return .init(networkParams: BitcoinNetwork.mainnet.networkParams, walletPublicKey: walletPublicKey, compressedWalletPublicKey: compressedWalletPublicKey)
    }()

    @Test
    func unsortedOutputsTransaction() throws {
        // given
        let defaultAddress = try addressService.makeAddress(from: walletPublicKey, type: .default)
        let unspentOutputManager = try prepareFilledUnspentOutputManager(address: defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, unspentOutputManager: unspentOutputManager, addresses: [])
        let amountToSend = Amount(with: blockchain, type: .coin, value: 0.4)
        let fee = Fee(Amount(with: blockchain, type: .coin, value: 0.00004641), parameters: BitcoinFeeParameters(rate: 21))
        let destination = "bc1q67dmfccnax59247kshfkxcq6qr53wmwqfa4s28cupktj2amf5jus2j6qvt"

        let signatures = [
            Data(hex: "00325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B93C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B4"),
            Data(hex: "ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A7247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B07"),
        ]

        let transaction = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: defaultAddress.value,
            destinationAddress: destination,
            changeAddress: defaultAddress.value
        )

        // when
        let hashes = try txBuilder.buildForSign(transaction: transaction, sequence: 4294967290, sortType: .none)
        let signedTx = try txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: 4294967290, sortType: .none)

        // then
        let expectedHashes = [
            Data(hex: "8272779353EAD7848859916DFA4E6ED4DAA54989CA6258566D0FFEDEC2002400"),
            Data(hex: "5624DB10BC172D5300C03EB50E3A1B2947CDCE4C89F483994DF07BB81EB97EA8"),
        ]

        let expectedSignedTransaction = Data(hex: "01000000000102DF05DDAF1B9E0D7A36672DA32986499F5EC8B3946429D16E1CD6736CF4A3FECF0100000000FAFFFFFFEF0788C82E89047D926062A41C8500C4FE896069E95C37251D6B8CEED67A908B0000000000FAFFFFFF02005A620200000000220020D79BB4E313E9A85557D685D363601A00E9176DC04F6B051F1C0D97257769A4B9AF04B90000000000160014309A0C6EFA0DA7966D5C42DC5A928F6BAF0E47EF02463043021F325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B902203C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B40121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D02483045022100ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A02207247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B070121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D00000000")

        #expect(hashes == expectedHashes)
        #expect(signedTx == expectedSignedTransaction)
    }

    @Test
    func sortedOutputsTransaction() throws {
        // given
        let defaultAddress = try addressService.makeAddress(from: walletPublicKey, type: .default)
        let unspentOutputManager = try prepareFilledUnspentOutputManager(address: defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, unspentOutputManager: unspentOutputManager, addresses: [])
        let amountToSend = Amount(with: blockchain, type: .coin, value: 0.4)
        let fee = Fee(Amount(with: blockchain, type: .coin, value: 0.00004641), parameters: BitcoinFeeParameters(rate: 21))
        let destination = "bc1q67dmfccnax59247kshfkxcq6qr53wmwqfa4s28cupktj2amf5jus2j6qvt"

        let signatures = [
            Data(hex: "00325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B93C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B4"),
            Data(hex: "ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A7247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B07"),
        ]

        let transaction = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: defaultAddress.value,
            destinationAddress: destination,
            changeAddress: defaultAddress.value
        )

        // when
        let hashes = try txBuilder.buildForSign(transaction: transaction, sequence: 4294967290, sortType: .bip69)
        let signedTx = try txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: 4294967290, sortType: .bip69)

        // then
        let expectedHashes = [
            Data(hex: "524AA09FDD0F8B414E2C66C650C9853C020963D56B84CE3049FDDD56869E5EEA"),
            Data(hex: "CA0F139AD25974812C294544229ECE7D3293B9E53680AC63B83B3BC1B2FC22BD"),
        ]

        let expectedSignedTransaction = Data(hex: "01000000000102EF0788C82E89047D926062A41C8500C4FE896069E95C37251D6B8CEED67A908B0000000000FAFFFFFFDF05DDAF1B9E0D7A36672DA32986499F5EC8B3946429D16E1CD6736CF4A3FECF0100000000FAFFFFFF02AF04B90000000000160014309A0C6EFA0DA7966D5C42DC5A928F6BAF0E47EF005A620200000000220020D79BB4E313E9A85557D685D363601A00E9176DC04F6B051F1C0D97257769A4B902463043021F325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B902203C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B40121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D02483045022100ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A02207247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B070121036DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D00000000")

        #expect(hashes == expectedHashes)
        #expect(signedTx == expectedSignedTransaction)
    }

    private func prepareFilledUnspentOutputManager(address: any BlockchainSdk.Address) throws -> UnspentOutputManager {
        let unspentOutputManager: UnspentOutputManager = .bitcoin(address: address, isTestnet: false)
        let outputs = [
            UnspentOutput(
                blockId: .random(in: 1 ... 100_000),
                txId: "8b907ad6ee8c6b1d25375ce9696089fec400851ca46260927d04892ec88807ef",
                index: 0,
                amount: 39920000
            ),
            UnspentOutput(
                blockId: .random(in: 1 ... 100_000),
                txId: "cffea3f46c73d61c6ed1296494b3c85e9f498629a32d67367a0d9e1bafdd05df",
                index: 1,
                amount: 12210000
            ),
        ]

        unspentOutputManager.update(outputs: outputs, for: address)
        return unspentOutputManager
    }
}

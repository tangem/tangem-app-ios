//
//  EthereumTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk
import Testing
import WalletCore
@testable import BlockchainSdk

struct EthereumTransactionTests {
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let sizeTester = TransactionSizeTesterUtility()
    private let privateKeyRaw = Data(hex: "e120fc1ef9d193a851926ebd937c3985dc2c4e642fb3d0832317884d5f18f3b3")

    @Test
    func defaultAddressGeneration() throws {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let walletPubKey = Data(hex: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")
        let expectedAddress = "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"
        let address = try addressService.makeAddress(from: walletPubKey).value

        #expect(address == expectedAddress)
    }

    @Test
    func validationAddress() {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        #expect(addressService.validate("0xc63763572d45171e4c25ca0818b44e5dd7f5c15b"))
    }

    @Test
    func legacyCoinTransfer() throws {
        // given
        let rawPublicKey = Data(hex: "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F")
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let signature = Data(hex: "B945398FB90158761F6D61789B594D042F0F490F9656FBFFAE8F18B49D5F30054F43EE43CCAB2703F0E2E4E61D99CF3D4A875CD759569787CF0AED02415434C6")
        let destinationAddress = "0x7655b9b19ffab8b897f836857dae22a1e7f8d735"
        let nonce = 15
        let walletAddress = "0xb1123efF798183B7Cb32F62607D3D39E950d9cc3"
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)
        let sendAmount = Amount(with: blockchain, type: .coin, value: 0.1)
        let feeParameters = EthereumLegacyFeeParameters(gasLimit: BigUInt(21000), gasPrice: BigUInt(476190476190))

        // feeAmount doesn't matter. The EthereumFeeParameters used to build the transaction
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transaction = Transaction(
            amount: sendAmount,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: nonce)
        )

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 1, sourceAddress: sourceAddress)
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(
            transaction: transaction,
            signatureInfo: signatureInfo
        )

        // then
        let expectedHashToSign = Data(hex: "BDBECF64B443F82D1F9FDA3F2D6BA69AF6D82029B8271339B7E775613AE57761")
        let expectedSignedTransaction = Data(hex: "F86C0F856EDF2A079E825208947655B9B19FFAB8B897F836857DAE22A1E7F8D73588016345785D8A00008025A0B945398FB90158761F6D61789B594D042F0F490F9656FBFFAE8F18B49D5F3005A04F43EE43CCAB2703F0E2E4E61D99CF3D4A875CD759569787CF0AED02415434C6")

        sizeTester.testTxSize(hashToSign)
        #expect(hashToSign == expectedHashToSign)
        #expect(signedTransaction == expectedSignedTransaction)
    }

    @Test(arguments: [
        LegacyTokenTransferTestCase.Success.usdcToken_correctData,
        LegacyTokenTransferTestCase.Success.nftERC721Token_correctData,
        LegacyTokenTransferTestCase.Success.nftERC1155Token_correctData,
    ])
    func legacyTokenTransfer_success(testCase: LegacyTokenTransferTestCase.Success) throws {
        // given
        let privateKey = WalletCore.PrivateKey(data: privateKeyRaw)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)

        // when
        let (transaction, transactionBuilder) = try makeTransactionForLegacyTokenTransfer(
            token: testCase.token,
            publicKey: publicKey
        )

        // then
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        #expect(hashToSign == testCase.transactionData.expectedHashToSign)

        let signature = try #require(privateKey.sign(digest: hashToSign, curve: .secp256k1))
        let signature64 = signature.prefix(64)

        let signatureInfo = SignatureInfo(signature: signature64, publicKey: publicKey.data, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        #expect(signedTransaction.hex() == testCase.transactionData.expectedSignedTransaction.hex(), testCase.name)
    }

    @Test(arguments: [
        LegacyTokenTransferTestCase.Failure.nftUnknownStandardToken_throwsError,
    ])
    func legacyTokenTransfer_failure(testCase: LegacyTokenTransferTestCase.Failure) throws {
        // given
        let privateKey = WalletCore.PrivateKey(data: privateKeyRaw)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)

        // when
        let (transaction, transactionBuilder) = try makeTransactionForLegacyTokenTransfer(
            token: testCase.token,
            publicKey: publicKey
        )

        // then
        #expect(throws: testCase.error) {
            try transactionBuilder.buildForSign(transaction: transaction)
        }
    }

    /// https://polygonscan.com/tx/0x8f7c7ffddfc9f45370cc5fbeb49df65bdf8976ba606d20705eea965ba96a1e8d
    @Test
    func EIP1559TokenTransfer() throws {
        // given
        let rawPublicKey = Data(hex: "043b08e56e38404199eb3320f32fdc7557029d4a4c39adae01cc47afd86cfa9a25fcbfaa2acda3ab33560a1d482a2088f3bb2c7b313fd11f50dd8fe508165d4ecf")
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let signature = Data(hex: "b8291b199416b39434f3c3b8cfd273afb41fa25f2ae66f8a4c56b08ad1749a122148b8bbbdeb7761031799ffbcbc7c0ee1dd4482f516bd6a33387ea5bce8cb7d")

        let walletAddress = "0x29010F8F91B980858EB298A0843264cfF21Fd9c9"
        let contractAddress = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)
        let token = Token(name: "Tether", symbol: "USDT", contractAddress: contractAddress, decimalCount: 6)

        let nonce = 195
        let sendValue = Amount(with: blockchain, type: .token(value: token), value: 1)
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(47525),
            maxFeePerGas: BigUInt(138077377799),
            priorityFee: BigUInt(30000000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 137, sourceAddress: sourceAddress)
        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: nonce)
        )

        // then
        let expectedHashToSign = Data(hex: "7843727fd03b42156222548815759dda5ac888033372157edffdde58fc05eff5")
        let expectedSignedTransaction = Data(hex: "0x02f8b3818981c38506fc23ac008520260d950782b9a594c2132d05d31c914a87c6611c10748aeb04b58e8f80b844a9059cbb00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c6700000000000000000000000000000000000000000000000000000000000f4240c080a0b8291b199416b39434f3c3b8cfd273afb41fa25f2ae66f8a4c56b08ad1749a12a02148b8bbbdeb7761031799ffbcbc7c0ee1dd4482f516bd6a33387ea5bce8cb7d")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        #expect(hashToSign == expectedHashToSign)

        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        #expect(signedTransaction.hex() == expectedSignedTransaction.hex())
    }

    /// https://polygonscan.com/tx/0x2cb6831f4c1cb7b888707489cd60c42ff222b5b3230d74f25434d936c2ba7419
    @Test
    func EIP1559CoinTransfer() throws {
        // given
        let rawPublicKey = Data(hex: "043b08e56e38404199eb3320f32fdc7557029d4a4c39adae01cc47afd86cfa9a25fcbfaa2acda3ab33560a1d482a2088f3bb2c7b313fd11f50dd8fe508165d4ecf")
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let signature = Data(hex: "56DF71FF2A7FE93D2363056FE5FF32C51E5AC71733AF23A82F3974CB872537E95B60D6A0042CC34724DB84E949EEC8643761FE9027E9E7B1ED3DA23D8AB7C0A4")

        let walletAddress = "0x29010F8F91B980858EB298A0843264cfF21Fd9c9"
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let nonce = 196
        let sendValue = Amount(with: blockchain, type: .coin, value: 1)
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(21000),
            maxFeePerGas: BigUInt(4478253867089),
            priorityFee: BigUInt(31900000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 137, sourceAddress: sourceAddress)
        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: nonce)
        )

        // then
        let expectedHashToSign = Data(hex: "925f1debbb96941544aefe6a5532508e51f2b8ae1f3a911abfb24b83af610400")
        let expectedSignedTransaction = Data(hex: "0x02f877818981c485076d635f00860412acbb20518252089490e4d59c8583e37426b37d1d7394b6008a987c67880de0b6b3a764000080c080a056df71ff2a7fe93d2363056fe5ff32c51e5ac71733af23a82f3974cb872537e9a05b60d6a0042cc34724db84e949eec8643761fe9027e9e7b1ed3da23d8ab7c0a4")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        #expect(hashToSign == expectedHashToSign)

        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        #expect(signedTransaction.hex() == expectedSignedTransaction.hex())
    }

    /// https://basescan.org/tx/0xb0df52cacd4a8d283e7f5ffe7b3f6d867fc5cb496f679b69b0b09a59651eb0e5
    @Test
    func EIP1559TokenApprove() throws {
        // given
        let rawPublicKey = Data(hex: "0x04c0b0bebaf7cec052a1fb2919c83a3d192713a65c3675a22ad9a2f76d5da1cfb0d4fec9da0bc71b5a405758a2e0349e2d151bfff6ec3d50441f0adb947a8a44a1")
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let signature = Data(hex: "0xcc6163663ccdadf4489e9753b0307c0fb1eed7fe92a7b0a6b3cb0f6d24f9109e7dd41e4e30c6777b27688527af3c4ec69ed053246ca05d1b3b8c3da127c30eb0")

        let walletAddress = "0xF686Cc42C39e942D5B4a237286C5A55B451bD6F0"
        let spenderAddress = "0x111111125421cA6dc452d289314280a0f8842A65"
        let contractAddress = "0x940181a94a35a4569e4529a3cdfb74e38fd98631"
        let destinationAddress = contractAddress
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(47000),
            maxFeePerGas: BigUInt(7250107),
            priorityFee: BigUInt(2000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let amountToSpend = BigUInt("115792089237316195423570985008687907853269984665640564039457584007913129639935") // 10^256 - 1
        let tokenMethod = ApproveERC20TokenMethod(spender: spenderAddress, amount: amountToSpend) // approve(address spender,uint256 amount)

        let nonce = 10

        let param = EthereumTransactionParams(data: tokenMethod.data, nonce: nonce)

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 8453, sourceAddress: sourceAddress)
        let transaction = Transaction(
            amount: .zeroCoin(for: blockchain),
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: param
        )

        // then
        let expectedHashToSign = Data(hex: "0xbbada4215ac1d69b8c30449afd4dae224d32177c5a80877d4220756ad14b9852")
        let expectedSignedTransaction = Data(hex: "0x02f8af8221050a831e8480836ea0bb82b79894940181a94a35a4569e4529a3cdfb74e38fd9863180b844095ea7b3000000000000000000000000111111125421ca6dc452d289314280a0f8842a65ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc001a0cc6163663ccdadf4489e9753b0307c0fb1eed7fe92a7b0a6b3cb0f6d24f9109ea07dd41e4e30c6777b27688527af3c4ec69ed053246ca05d1b3b8c3da127c30eb0")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        #expect(hashToSign.hex() == expectedHashToSign.hex())

        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        #expect(signedTransaction.hex() == expectedSignedTransaction.hex())
    }

    /// https://basescan.org/tx/0x4648aee1b8498245eb425c94efcc7e4df8c1524be977fc43862b6a67038dcefb
    @Test
    func EIP1559TokenSwap() throws {
        // given
        let rawPublicKey = Data(hex: "0x04c0b0bebaf7cec052a1fb2919c83a3d192713a65c3675a22ad9a2f76d5da1cfb0d4fec9da0bc71b5a405758a2e0349e2d151bfff6ec3d50441f0adb947a8a44a1")
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let signature = Data(hex: "0x0982b50e820042d00a51ac23029cd66bdd88c6300890120be54a05afedbe938943e0e8f475dba0d9cd9d4a38f02e29662ef106c3bede1938230a32a2f23e8106")

        let walletAddress = "0xF686Cc42C39e942D5B4a237286C5A55B451bD6F0"
        let contractAddress = "0x111111125421ca6dc452d289314280a0f8842a65"
        let destinationAddress = contractAddress
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(156360),
            maxFeePerGas: BigUInt(5672046),
            priorityFee: BigUInt(1000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // swap(address executor,tuple (address,address,address,address,uint256,uint256,uint256) desc,bytes data)
        let payload = Data(hexString: "0x07ed2379000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000940181a94a35a4569e4529a3cdfb74e38fd98631000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000f686cc42c39e942d5b4a237286c5a55b451bd6f0000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000002713e3fabbc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001410000000000000000000000000001230001090000f30000b700006800004e802026678dcd940181a94a35a4569e4529a3cdfb74e38fd98631beec796a4a2a27b687e1d48efad3805d7880052200000000000000000000000000000000000000000000000000002d79883d20000020d6bdbf78940181a94a35a4569e4529a3cdfb74e38fd9863102a0000000000000000000000000000000000000000000000000000002713e3fabbcee63c1e5003d5d143381916280ff91407febeb52f2b60f33cf940181a94a35a4569e4529a3cdfb74e38fd986314101420000000000000000000000000000000000000600042e1a7d4d0000000000000000000000000000000000000000000000000000000000000000c061111111125421ca6dc452d289314280a0f8842a6500206b4be0b9111111125421ca6dc452d289314280a0f8842a65000000000000000000000000000000000000000000000000000000000000002df1ec3e")

        let nonce = 11

        let param = EthereumTransactionParams(data: payload, nonce: nonce)

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 8453, sourceAddress: sourceAddress)
        let transaction = Transaction(
            amount: .zeroCoin(for: blockchain),
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: param
        )

        // then
        let expectedHashToSign = Data(hex: "b59deacf74401648c860a4cfc9bee40d0da1502c05efa278d4afdb6dfe4bd8f3")
        let expectedSignedTransaction = Data(hex: "02f903158221050b830f424083568c6e830262c894111111125421ca6dc452d289314280a0f8842a6580b902a807ed2379000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000940181a94a35a4569e4529a3cdfb74e38fd98631000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000f686cc42c39e942d5b4a237286c5a55b451bd6f0000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000002713e3fabbc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001410000000000000000000000000001230001090000f30000b700006800004e802026678dcd940181a94a35a4569e4529a3cdfb74e38fd98631beec796a4a2a27b687e1d48efad3805d7880052200000000000000000000000000000000000000000000000000002d79883d20000020d6bdbf78940181a94a35a4569e4529a3cdfb74e38fd9863102a0000000000000000000000000000000000000000000000000000002713e3fabbcee63c1e5003d5d143381916280ff91407febeb52f2b60f33cf940181a94a35a4569e4529a3cdfb74e38fd986314101420000000000000000000000000000000000000600042e1a7d4d0000000000000000000000000000000000000000000000000000000000000000c061111111125421ca6dc452d289314280a0f8842a6500206b4be0b9111111125421ca6dc452d289314280a0f8842a65000000000000000000000000000000000000000000000000000000000000002df1ec3ec080a00982b50e820042d00a51ac23029cd66bdd88c6300890120be54a05afedbe9389a043e0e8f475dba0d9cd9d4a38f02e29662ef106c3bede1938230a32a2f23e8106")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        #expect(hashToSign.hex() == expectedHashToSign.hex())

        let signatureInfo = SignatureInfo(signature: signature, publicKey: rawPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        #expect(signedTransaction.hex() == expectedSignedTransaction.hex())
    }

    @Test
    func buildDummyTransactionForL1() throws {
        // given
        let rawPublicKey = Data(repeating: 0x0, count: 65) // Just a dummy value to satisfy the compiler
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let walletAddress = Data(repeating: 0x0, count: 20).hexString // Just a dummy value to satisfy the compiler
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let sendValue = EthereumUtils.mapToBigUInt(1 * blockchain.decimalValue).serialize()
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(21000),
            maxFeePerGas: BigUInt(4478253867089),
            priorityFee: BigUInt(31900000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transactionBuilder = EthereumTransactionBuilder(chainId: 1, sourceAddress: sourceAddress)

        // when
        let l1Data = try transactionBuilder.buildDummyTransactionForL1(
            destination: destinationAddress,
            value: sendValue.hex(),
            data: nil,
            fee: fee
        )

        // then
        #expect(l1Data.hex(.uppercase) == "02F2010185076D635F00860412ACBB20518252089490E4D59C8583E37426B37D1D7394B6008A987C67880DE0B6B3A764000080C0")
    }

    @Test
    func parseBalance() {
        let hex = "0x373c91e25f1040"
        let hex2 = "0x00000000000000000000000000000000000000000000000000373c91e25f1040"
        #expect(EthereumUtils.parseEthereumDecimal(hex, decimalsCount: 18)!.description == "0.015547720984891456")
        #expect(EthereumUtils.parseEthereumDecimal(hex2, decimalsCount: 18)!.description == "0.015547720984891456")

        // vBUSD contract sends extra zeros
        let vBUSDHexWithExtraZeros = "0x0000000000000000000000000000000000000000000000000000005a8c504ec900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        let vBUSDHexWithoutExtraZeros = "0x0000000000000000000000000000000000000000000000000000005a8c504ec9"
        #expect(EthereumUtils.parseEthereumDecimal(vBUSDHexWithExtraZeros, decimalsCount: 18)!.description == "0.000000388901129929")
        #expect(EthereumUtils.parseEthereumDecimal(vBUSDHexWithoutExtraZeros, decimalsCount: 18)!.description == "0.000000388901129929")

        // This is rubbish and we don't expect to receive this but at least it should not throw exceptions
        let tooBig = "0x01234567890abcdef01234567890abcdef01234501234567890abcdef01234567890abcdef01234501234567890abcdef012345def01234501234567890abcdef012345def01234501234567890abcdef012345def01234501234567890abcdef01234567890abcdef012345"
        #expect(EthereumUtils.parseEthereumDecimal(tooBig, decimalsCount: 18) == nil)
    }

    @Test
    func buildingApproveTransactionPayload() throws {
        let rawPublicKey = Data(repeating: 0x0, count: 65) // Just a dummy value to satisfy the compiler
        let walletPublicKey = Wallet.PublicKey(seedKey: rawPublicKey, derivationType: nil)
        let walletAddress = Data(repeating: 0x0, count: 20).hexString // Just a dummy value to satisfy the compiler
        let sourceAddress = PlainAddress(value: walletAddress, publicKey: walletPublicKey, type: .default)

        let transactionBuilder = EthereumTransactionBuilder(chainId: 10, sourceAddress: sourceAddress)
        let amount = try #require(Decimal(stringValue: "1146241"))

        let payload = transactionBuilder.buildForApprove(
            spender: "0x111111125421cA6dc452d289314280a0f8842A65",
            amount: amount
        )

        // https://optimistic.etherscan.io/tx/0x97141f7a1b450739bcf097fe41ca76c83897c0cc618e43b08fa0267865451c2b
        #expect(
            payload.hex().addHexPrefix() ==
                "0x095ea7b3000000000000000000000000111111125421ca6dc452d289314280a0f8842a650000000000000000000000000000000000000000000000000000000000117d81"
        )
    }

    @Test(
        arguments: [
            // https://optimistic.etherscan.io/tx/0x89a6b62628d326902df50f543996e9403df9a5d2ae5be415f7cdaa1a98464fd4
            TokenTransferPayloadTestCase.Success.usdcToken_correctPayload,
            TokenTransferPayloadTestCase.Success.nftERC721Token_correctPayload,
            TokenTransferPayloadTestCase.Success.nftERC1155Token_correctPayload,
        ]
    )
    func buildingTokenTransferTransactionPayload_success(testCase: TokenTransferPayloadTestCase.Success) throws {
        // given
        let privateKey = WalletCore.PrivateKey(data: privateKeyRaw)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)

        let (_, transactionBuilder) = try makeTransactionForLegacyTokenTransfer(token: testCase.token, publicKey: publicKey)

        // when
        let payload = try transactionBuilder.buildForTokenTransfer(
            destination: "0x75739A5bd4B781cF38c59B9492ef9639e46688Bf",
            amount: .init(
                with: .optimism(testnet: false),
                type: .token(value: testCase.token),
                value: try #require(Decimal(stringValue: "0.001"))
            )
        )

        // then
        #expect(payload.hex().addHexPrefix() == testCase.refPayload, testCase.name)
    }

    @Test(arguments: [
        TokenTransferPayloadTestCase.Failure.nftUnknownStandardToken_throwsError,
    ])
    func buildingTokenTransferTransactionPayload_failure(testCase: TokenTransferPayloadTestCase.Failure) throws {
        // given
        let privateKey = WalletCore.PrivateKey(data: privateKeyRaw)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)

        let (_, transactionBuilder) = try makeTransactionForLegacyTokenTransfer(token: testCase.token, publicKey: publicKey)

        // when
        // then
        #expect(throws: testCase.error) {
            try transactionBuilder.buildForTokenTransfer(
                destination: "0x75739A5bd4B781cF38c59B9492ef9639e46688Bf",
                amount: .init(
                    with: .optimism(testnet: false),
                    type: .token(value: testCase.token),
                    value: try #require(Decimal(stringValue: "0.001"))
                )
            )
        }
    }

    @Test
    func feeHistoryParse() throws {
        let json =
            """
            {
                "oldestBlock": "0x3906bc3",
                "reward": [
                    [
                        "0x861c47fc9",
                        "0xa7a35bb7a",
                        "0xba43b17ec"
                    ],
                    [
                        "0x6fc23ac00",
                        "0x6fc23ac00",
                        "0x7aef43037"
                    ],
                    [
                        "0x6fc23ac00",
                        "0x7aef43262",
                        "0x9c765ad41"
                    ],
                    [
                        "0x737be1dc3",
                        "0x7558be371",
                        "0x7aef43358"
                    ],
                    [
                        "0x6fc23aeec",
                        "0x7aef41ea5",
                        "0x9502f38ce"
                    ]
                ],
                "baseFeePerGas": [
                    "0x5c14",
                    "0x5a1e",
                    "0x5abc",
                    "0x583d",
                    "0x5732",
                    "0x54f9"
                ],
                "gasUsedRatio": [
                    0.3294011263207626,
                    0.55512407750046,
                    0.2798693487006748,
                    0.4054004895571093,
                    0.29574768320265493
                ]
            }
            """

        let decoded = try JSONDecoder().decode(EthereumFeeHistoryResponse.self, from: json.data(using: .utf8)!)
        let feeHistory = try EthereumMapper.mapFeeHistory(decoded)
        let response = EthereumMapper.mapToEthereumEIP1559FeeResponse(gasLimit: 21000, feeHistory: feeHistory)

        let feeParameters = [
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.low.max,
                priorityFee: response.fees.low.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.market.max,
                priorityFee: response.fees.market.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.fast.max,
                priorityFee: response.fees.fast.priority
            ),
        ]

        let fees = feeParameters.map { parameters in
            parameters.calculateFee(decimalValue: pow(Decimal(10), 18))
        }

        #expect(fees[0] < fees[1] && fees[1] < fees[2])
    }
}

// MARK: - Helpers

extension EthereumTransactionTests {
    func makeTransactionForLegacyTokenTransfer(token: Token, publicKey: PublicKey) throws -> (transaction: Transaction, builder: EthereumTransactionBuilder) {
        let walletAddress = AnyAddress(publicKey: publicKey, coin: .ethereum).description

        let destinationAddress = "0x7655b9b19ffab8b897f836857dae22a1e7f8d735"
        let sourceAddress = PlainAddress(
            value: walletAddress,
            publicKey: Wallet.PublicKey(seedKey: publicKey.data, derivationType: .none),
            type: .default
        )

        let nonce = 15
        let sendValue = Amount(with: blockchain, type: .token(value: token), value: try #require(Decimal(stringValue: "0.1")))
        let feeParameters = EthereumLegacyFeeParameters(gasLimit: BigUInt(21000), gasPrice: BigUInt(476190476190))
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transactionBuilder = EthereumTransactionBuilder(chainId: 1, sourceAddress: sourceAddress)

        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: nonce)
        )

        return (transaction: transaction, builder: transactionBuilder)
    }
}

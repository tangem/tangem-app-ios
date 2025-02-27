@testable import BlockchainSdk
import Testing
import CryptoKit
import WalletCore

struct BinanceTests {
    private let secp256k1PublicKey = "039BBD8C96ADA3D42648FBE52FB40F3DAE106E7552EFE42A3F51583300AD5E74AB"
    private let txBuilder: BinanceTransactionBuilder

    init() throws {
        txBuilder = try BinanceTransactionBuilder(
            walletPublicKey: Data(hexString: secp256k1PublicKey),
            isTestnet: false
        )
    }

    @Test
    func correctCoinTransaction() throws {
        // given
        let blockchain = Blockchain.binance(testnet: false)

        let transaction = Transaction(
            amount: .init(with: blockchain, value: Decimal(stringValue: "0.5")!),
            fee: .init(.init(with: blockchain, value: Decimal(stringValue: "0.001")!)),
            sourceAddress: "1srjlyhvztajn9nhvxjlz6xus6w59a63vmkh4jp", // Address from public key
            destinationAddress: "58567F7A51a58708C8B40ec592A38bA64C0697De",
            changeAddress: "1srjlyhvztajn9nhvxjlz6xus6w59a63vmkh4jp",
            params: BinanceTransactionParams(memo: "123456")
        )

        // when
        let messageForSign = txBuilder.buildForSign(transaction: transaction)!.encodeForSignature()
        let signature = Data(hex: "208C10A1A865A95D40F99A5ED3598D11D8EF25234990038A9D32C1E8B36074CA4D86A26BF8214A99A5574A18F657812A4F6B9E881FBE1CDA99265AC6E9F1DEA900")
        let messageForSend = try txBuilder.buildForSend(signature: signature)?.encode()

        // then
        #expect("4915df6534503aca75f87c6eb47cf7e6bad0dfe7d9617da1153f5d9538efb474" == messageForSign.hexString.lowercased())
        #expect(
            "b301f0625dee0a362a2c87fa0a220a1480e5f25d825f6532ceec34be2d1b90d3a85eea2c120a0a03424e421080e1eb17120c120a0a03424e421080e1eb17126b0a26eb5ae98721039bbd8c96ada3d42648fbe52fb40f3dae106e7552efe42a3f51583300ad5e74ab1241208c10a1a865a95d40f99a5ed3598d11d8ef25234990038a9d32c1e8b36074ca4d86a26bf8214a99a5574a18f657812a4f6b9e881fbe1cda99265ac6e9f1dea9001a063132333435362001" ==
                messageForSend?.hexString.lowercased()
        )
    }

    @Test
    func correctTokenTransaction() throws {
        // given
        let token = Token(
            name: "tether",
            symbol: "Tether",
            contractAddress: "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs",
            decimalCount: 6
        )
        let amount = Amount(with: token, value: Decimal(stringValue: "0.1")!)

        let transaction = Transaction(
            amount: amount,
            fee: .init(.init(with: .binance(testnet: false), value: Decimal(stringValue: "0.001")!)),
            sourceAddress: "1srjlyhvztajn9nhvxjlz6xus6w59a63vmkh4jp", // Address from public key
            destinationAddress: "58567F7A51a58708C8B40ec592A38bA64C0697De",
            changeAddress: "1srjlyhvztajn9nhvxjlz6xus6w59a63vmkh4jp",
            contractAddress: "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs",
            params: BinanceTransactionParams(memo: "123456")
        )

        // when
        let messageForSign = txBuilder.buildForSign(transaction: transaction)!.encodeForSignature()
        let signature = Data(hex: "81274C6C2262DC9679CDD98FB58A415E91078429800A07A6DC26A0C3DAB5B4730FA467CD1FA47C8CD6E16ABA6598438379E53D71109013C6E87C916AA338B0E500")
        let messageForSend = try txBuilder.buildForSend(signature: signature)?.encode()

        // then
        #expect(messageForSign.hexString.lowercased() == "b57a50f35828ea1ea767b9985d65f468343ffd655cf6a114f8ab001cf400ea02")
        #expect(
            messageForSend?.hexString.lowercased() == "8e02f0625dee0a90012a2c87fa0a4f0a1480e5f25d825f6532ceec34be2d1b90d3a85eea2c12370a304551437845366d5574514a4b466e476661524f544b4f74316c5a6244696958316b4369785276374e773249645f7344731080ade204123912370a304551437845366d5574514a4b466e476661524f544b4f74316c5a6244696958316b4369785276374e773249645f7344731080ade204126b0a26eb5ae98721039bbd8c96ada3d42648fbe52fb40f3dae106e7552efe42a3f51583300ad5e74ab124181274c6c2262dc9679cdd98fb58a415e91078429800a07a6dc26a0c3dab5b4730fa467cd1fa47c8cd6e16aba6598438379e53d71109013c6e87c916aa338b0e5001a063132333435362001"
        )
    }
}

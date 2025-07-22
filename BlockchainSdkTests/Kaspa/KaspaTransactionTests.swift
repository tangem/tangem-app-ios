//
//  KaspaTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import Testing
@testable import BlockchainSdk

struct KaspaTransactionTests {
    private let blockchain = Blockchain.kaspa(testnet: false)

    /// https://kas.fyi/transaction/113471470e4ad43324aad78880b092e153adee6cfc1236fbf17f715daa2071be
    @Test
    func coinTransaction() async throws {
        // given
        let address = try AddressServiceFactory(blockchain: .kaspa(testnet: false)).makeAddressService().makeAddress(from: Data(hexString: "03401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01deb"))
        let unspentOutputManager: UnspentOutputManager = .kaspa(address: address)
        let outputs: [UnspentOutput] = [
            UnspentOutput(blockId: 1, txId: "414f096361040f27e3ebfd02965c27d1492a69880dbf1544bf213e7159709134", index: 0, amount: 20000000),
            UnspentOutput(blockId: 2, txId: "5f7deb4c490de237e0dcc9dae4216f80247a671ca30eaab411d2963c6e070113", index: 1, amount: 19736854),
            UnspentOutput(blockId: 3, txId: "c97e84228b68aa37a0c51c5a93f0005eb9543a353b6cf59c33052eab33f16e0b", index: 0, amount: 20000000),
        ]

        unspentOutputManager.update(outputs: outputs, for: address)
        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: .init(seedKey: Data(hexString: "03401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01deb"), derivationType: .none),
            unspentOutputManager: unspentOutputManager,
            isTestnet: false
        )

        let destination = "kaspa:qyptjw50kqcp6a7xmx8juv0xvmgtmem4fvlte88clt2kafas863narspv9sj34u"
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: Decimal(stringValue: "0.2")!),
            fee: Fee(Amount(with: blockchain, value: Decimal(stringValue: "0.00004297")!)),
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        let signatures = [
            Data(hexString: "401dc920bf148e0fcdcfae009b9dc805553f74f883aaff8a5c0445a1169d89196035a177eb33dc57076fe6c4453843e11e36d229ee895bfdd18f7b63131d5889"),
            Data(hexString: "0a51d8d2e737f1cf8d3440e31736aa07a230a3ec4f811d50f8abc6f86369a27c3425813510a06f9f5648afda58d1e15a91be29d41779c16d49415cfe962c9095"),
            Data(hexString: "c0aebb30e5638c7f98d870ab40f43fe2a6bdec0ed848f8e9622cb8733df9988278501064c5876e978e1c9fbd78bf96111b94487c5e9fbb99399342a9fb16667b"),
        ]

        // when
        let (kaspaTransaction, hashes) = try await txBuilder.buildForSign(transaction: transaction)
        let builtTransaction = txBuilder.mapToTransaction(transaction: kaspaTransaction, signatures: signatures)

        // then

        let expectedHashes = [
            Data(hex: "80a72a2ba65dba21a64527015ceab6312f5da668cd83285fa63bcd55b6f5610d"),
            Data(hex: "f48c41fa6d58273438278100ab0ae3e0a07bfedd1f00561030873a381421dd08"),
            Data(hex: "9e4d470b5d4888d4b0e036281142af776f3a1b7d9a1c4b2d8550f2ecd41d7bea"),
        ]

        let expectedTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "414f096361040f27e3ebfd02965c27d1492a69880dbf1544bf213e7159709134",
                        index: 0
                    ),
                    signatureScript: "41401dc920bf148e0fcdcfae009b9dc805553f74f883aaff8a5c0445a1169d89196035a177eb33dc57076fe6c4453843e11e36d229ee895bfdd18f7b63131d588901"
                ),
                .init(
                    previousOutpoint: .init(
                        transactionId: "5f7deb4c490de237e0dcc9dae4216f80247a671ca30eaab411d2963c6e070113",
                        index: 1
                    ),
                    signatureScript: "410a51d8d2e737f1cf8d3440e31736aa07a230a3ec4f811d50f8abc6f86369a27c3425813510a06f9f5648afda58d1e15a91be29d41779c16d49415cfe962c909501"
                ),
                .init(
                    previousOutpoint: .init(
                        transactionId: "c97e84228b68aa37a0c51c5a93f0005eb9543a353b6cf59c33052eab33f16e0b",
                        index: 0
                    ),
                    signatureScript: "41c0aebb30e5638c7f98d870ab40f43fe2a6bdec0ed848f8e9622cb8733df9988278501064c5876e978e1c9fbd78bf96111b94487c5e9fbb99399342a9fb16667b01"
                ),
            ],
            outputs: [
                .init(
                    amount: 20000000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2102b93a8fb0301d77c6d98f2e31e666d0bde7754b3ebc9cf8fad56ea7b03ea33e8eab",
                        version: 0
                    )
                ),
                // Change
                .init(
                    amount: 39732557,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab",
                        version: 0
                    )
                ),
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try encoder.encode(expectedTransaction)

        #expect(address.value == "kaspa:qyp5qxu7n45c8zx6pqhndy43p4qt02zxchc4723fuclpraty00gpm6c8edeys5s")
        #expect(hashes == expectedHashes)
        #expect(encodedBuiltTransaction == encodedExpectedTransaction)
    }

    /// https://kas.fyi/transaction/38db4297dd40486707e818c1aab331b9a25ae5d96f0c37f58b1f9a828cf34b70
    @Test
    func krc20TokenTransaction() async throws {
        // given
        let address = try AddressServiceFactory(blockchain: .kaspa(testnet: false)).makeAddressService().makeAddress(from: Data(hexString: "03401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01deb"))
        let unspentOutputManager: UnspentOutputManager = .kaspa(address: address)
        let outputs: [UnspentOutput] = [
            UnspentOutput(blockId: 1, txId: "113471470e4ad43324aad78880b092e153adee6cfc1236fbf17f715daa2071be", index: 1, amount: 39732557),
            UnspentOutput(blockId: 2, txId: "f8107be5d92cc4266a6def91fd30b3b8f7690a2f932eab6c254031caf8bbcacf", index: 0, amount: 39997245),
        ]

        unspentOutputManager.update(outputs: outputs, for: address)
        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: .init(seedKey: Data(hexString: "03401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01deb"), derivationType: .none),
            unspentOutputManager: unspentOutputManager,
            isTestnet: false
        )

        let token = Token(name: "GGMF", symbol: "GGMF", contractAddress: "GGMF", decimalCount: 8)
        let destination = "kaspa:qyptjw50kqcp6a7xmx8juv0xvmgtmem4fvlte88clt2kafas863narspv9sj34u"
        let feeParams = KaspaKRC20.TokenTransactionFeeParams(
            commitFee: Amount(with: blockchain, value: Decimal(stringValue: "0.00016573")!),
            revealFee: Amount(with: blockchain, value: Decimal(stringValue: "0.000041")!)
        )

        let fee = Fee(
            Amount(with: blockchain, value: Decimal(stringValue: "0.00020673")!),
            parameters: feeParams
        )

        let transaction = Transaction(
            amount: Amount(with: blockchain, type: .token(value: token), value: Decimal(stringValue: "1")!),
            fee: fee,
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        let signatures = [
            Data(hexString: "be3464a493fa8e8d3a4f630464904336a3b542ec73e6fadade8a500151c9dbbc6c9e65ea768bd02f5924ae80854cb3fbff71cae5040e7b54afcabb32a8fabf8f"),
            Data(hexString: "10da4a8a8424f3863a74cf99efdc6399717d84b44e054d711cf852c61b0de74f17e162d2d0fa4ddd7d34dda4d54e6d2c11e702900f8a5737aa55882188b2f64f"),
        ]

        let revealSignatures = [
            Data(hexString: "0cc61353440a03bd3239c6183916c36d895512ebb23b52cfb937e1c54c0b216028718515855b0a5202488d396503c3e495f6e3b8f0760006c0bad5f8636ee2db"),
        ]

        let commitRedeemScript = Data(hexString: "2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab0063076b6173706c65785100004c8b7b22616d74223a22313030303030303030222c226f70223a227472616e73666572222c2270223a226b72632d3230222c227469636b223a2247474d46222c22746f223a226b617370613a717970746a7735306b716370366137786d78386a75763078766d67746d656d3466766c74653838636c74326b616661733836336e617273707639736a333475227d68")

        // when
        let (txgroup, meta) = try await txBuilder.buildForSignKRC20(transaction: transaction)
        let hashes = txgroup.hashesCommit + txgroup.hashesReveal
        let builtTransaction = txBuilder.mapToTransaction(transaction: txgroup.kaspaCommitTransaction, signatures: signatures)
        let builtRevealTransaction = txBuilder.mapToRevealTransaction(
            transaction: txgroup.kaspaRevealTransaction,
            commitRedeemScript: commitRedeemScript,
            signatures: revealSignatures
        )

        // then

        let expectedHashes = [
            Data(hex: "3f6807d0e927233f6e792db8f4e8b932836a80d45d386cba63b17850e0470fd4"),
            Data(hex: "2788f1ddc6cbf080310d73d316702a5c61912ffdd86ea076db1c8f989ca48b84"),
            Data(hex: "7b0180298292e4c6937377f8666d8b119778f61611f4e51afb2a5941ff4aa88c"),
        ]

        let expectedTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "113471470e4ad43324aad78880b092e153adee6cfc1236fbf17f715daa2071be",
                        index: 1
                    ),
                    signatureScript: "41be3464a493fa8e8d3a4f630464904336a3b542ec73e6fadade8a500151c9dbbc6c9e65ea768bd02f5924ae80854cb3fbff71cae5040e7b54afcabb32a8fabf8f01"
                ),
                .init(
                    previousOutpoint: .init(
                        transactionId: "f8107be5d92cc4266a6def91fd30b3b8f7690a2f932eab6c254031caf8bbcacf",
                        index: 0
                    ),
                    signatureScript: "4110da4a8a8424f3863a74cf99efdc6399717d84b44e054d711cf852c61b0de74f17e162d2d0fa4ddd7d34dda4d54e6d2c11e702900f8a5737aa55882188b2f64f01"
                ),
            ],
            outputs: [
                // Dust(0.2 KAS) + feeEstimationRevealTransactionValue(0.000041)
                .init(
                    amount: 20004100,
                    scriptPublicKey: .init(
                        scriptPublicKey: "aa201775d37a12f5ae0835322a24ce3d99a4a7ba803ccbb4e0fc56498421fc5db94f87",
                        version: 0
                    )
                ),
                // Change
                .init(
                    amount: 59709129,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab",
                        version: 0
                    )
                ),
            ]
        )

        let expectedRevealTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "81425d682c91f2e6c7a59052d70fe30f127c7608977812ed8249dae985a634e0",
                        index: 0
                    ),
                    signatureScript: "410cc61353440a03bd3239c6183916c36d895512ebb23b52cfb937e1c54c0b216028718515855b0a5202488d396503c3e495f6e3b8f0760006c0bad5f8636ee2db014cbe2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab0063076b6173706c65785100004c8b7b22616d74223a22313030303030303030222c226f70223a227472616e73666572222c2270223a226b72632d3230222c227469636b223a2247474d46222c22746f223a226b617370613a717970746a7735306b716370366137786d78386a75763078766d67746d656d3466766c74653838636c74326b616661733836336e617273707639736a333475227d68"
                ),
            ],
            outputs: [
                .init(
                    amount: 20000000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab",
                        version: 0
                    )
                ),
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try encoder.encode(expectedTransaction)
        let encodedBuiltRevealTransaction = try encoder.encode(builtRevealTransaction)
        let encodedExpectedRevealTransaction = try encoder.encode(expectedRevealTransaction)

        #expect(address.value == "kaspa:qyp5qxu7n45c8zx6pqhndy43p4qt02zxchc4723fuclpraty00gpm6c8edeys5s")
        #expect(hashes == expectedHashes)
        #expect(encodedBuiltTransaction == encodedExpectedTransaction)
        #expect(encodedBuiltRevealTransaction == encodedExpectedRevealTransaction)
    }

    @Test
    func transactionHash() {
        let tx1 = KaspaTransaction(
            inputs: [
                .init(
                    transactionHash: Data(hexString: "4df1f7923708f6fa98f8d192cdb511666fc93c858d86fb7bc61bc7c13d54c9f4"),
                    outputIndex: 2,
                    amount: 0, // not used
                    script: Data(hexString: "415bfc0dde408a06ec6a39ae850986b49c2d0d5b83e47233b43012de3aedcecde75ebc239008060bd50633e8e1aeba891300ca74e8279dd591d8ceda60609afa6001")
                ),
            ],
            outputs: [
                .init(
                    amount: UInt64(500003000),
                    scriptPublicKey: .init(
                        script: Data(hexString: "aa207b1cfee1aa9cb2ab4eff9ff9593f88d3f0453f02e02790ac493f8eb712dce17787"),
                        version: 0
                    )
                ),
                .init(
                    amount: UInt64(3764387352),
                    scriptPublicKey: .init(
                        script: Data(hexString: "2035c82aa416591a1afb84d10b6d225899f27ce6b51381c03b8cf104c3906258d3ac"),
                        version: 0
                    )
                ),
            ]
        )

        let tx2 = KaspaTransaction(
            inputs: [
                .init(
                    transactionHash: Data(hexString: "03f30878b05fdfd6c47f749538f77629fd5e48c93233c36e737493caf6c67915"),
                    outputIndex: 0,
                    amount: 0, // not used
                    script: Data(hexString: "412fe34c676f75602942c9e63dc554e2f8abe4929436e8debf0cc5bd2efde012541afa6a300867742728390c73e0ac39b4778c314734f92806f9d236fa1c48f94301")
                ),
                .init(
                    transactionHash: Data(hexString: "c69a424df624c9c235f23afc0ce20afbfd56ea042f3123e9c464ffb8b2b2f33c"),
                    outputIndex: 0,
                    amount: 0, // not used
                    script: Data(hexString: "41596c4bb99592c5637accfaf9e3793b934ece1402e267f8d1e309d73cd5139c544305662442fdfe298bfd65bd884199ec83482f801bbc3dee76903ca5187b6deb01")
                ),
                .init(
                    transactionHash: Data(hexString: "2958f73001b95a36d8e51697fcb6d842b6068f49e9e46a73550e35527a40d878"),
                    outputIndex: 0,
                    amount: 0, // not used
                    script: Data(hexString: "414c35049eb692e2596c00541fb0812cd3a05a11b6cc368476272702295ba8252b27c077c4a256a30979d27d21d0ea99139581d0646c1162ec52535d2568c8995301")
                ),
                .init(
                    transactionHash: Data(hexString: "705624bb67706ddc1351868ee19d7642262810cd072acbf0b08fed6050283079"),
                    outputIndex: 0,
                    amount: 0, // not used
                    script: Data(hexString: "41de193ea21790d577bdbb29574cbfaf6444459e42de711cb60156f459ee725edb4fc223518ea77c60bc637256e1597e9681565d01f08195f8a8d071caee0d786301")
                ),
                .init(
                    transactionHash: Data(hexString: "7b5035caf767c7173915bfb880031e7222b1affa175343a9ca2a924e314a226d"),
                    outputIndex: 0,
                    amount: 0, // not used
                    script: Data(hexString: "41061dcffbbaedb3a03cd15b73677d7da8292f489c833b06ca7c77e6256173782e60e1b360a8f3c20e7a445ac0e63830295045c111571ef55635879f2b50493c0901")
                ),
            ],
            outputs: [
                .init(
                    amount: UInt64(57103393833),
                    scriptPublicKey: .init(
                        script: Data(hexString: "2035c82aa416591a1afb84d10b6d225899f27ce6b51381c03b8cf104c3906258d3ac"),
                        version: 0
                    )
                ),
            ]
        )

        #expect(tx1.transactionId?.hex() == "c2cb9d865f5085cd6f7f23365545c68d1eaca7e3cde9d231a64812be2c989a30")
        #expect(tx1.transactionHash?.hex() == "06661f542544b166259af2e5dd01fc873a8893bf1aa4fada36fb92dfce64b4b0")
        #expect(tx2.transactionId?.hex() == "d9cd38d294de5cce401330a91c97807b5433a377e043e99b66363fe5274477c9")
        #expect(tx2.transactionHash?.hex() == "b5b1f2be9ec7dd34ee0da90addcae9bb7bbba145b1460ad639017059f9e41829")
    }
}

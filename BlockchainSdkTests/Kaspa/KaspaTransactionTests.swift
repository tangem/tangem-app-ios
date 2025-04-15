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
    private let walletPublicKey = Data(hexString: "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F")

    @Test
    func schnorrTransaction() throws {
        // given
        let address = try KaspaAddressService(isTestnet: false).makeAddress(from: walletPublicKey)
        let unspentOutputManager: UnspentOutputManager = .kaspa(address: address)
        // Will select deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb
        let outputs: [UnspentOutput] = [
            UnspentOutput(blockId: 0, txId: "deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb", index: 0, amount: 10000000),
            UnspentOutput(blockId: 1, txId: "304db39069dc409acedf544443dcd4a4f02bfad4aeb67116f8bf087822c456af", index: 0, amount: 10000000),
            UnspentOutput(blockId: 2, txId: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a", index: 0, amount: 500000000),
        ]

        unspentOutputManager.update(
            outputs: outputs,
            // NOTE: Be careful that lockingScript is not same that we have for source address
            for: UTXOLockingScript(keyHash: Data(), data: Data(hexString: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"), type: .p2pk)
        )

        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: .empty,
            unspentOutputManager: unspentOutputManager,
            isTestnet: false
        )

        let destination = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: Decimal(stringValue: "0.001")!),
            fee: Fee(Amount(with: blockchain, value: Decimal(stringValue: "0.0003")!)),
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        let signatures = [
            Data(hexString: "E2747D4E00C55D69FA0B8ADFAFD07F41144F888E322D377878E83F25FD2E258B2E918EF79E151337D7F3BD0798D66FDCE04B07C30984424B13344F0A7CC40165"),
            Data(hexString: "4BF71C43DF96FC6B46766CAE30E97BD9018E9B98BB2C3645744A696AD26ECC780157EA9D44DC41D0BCB420175A5D3F543079F4263AA2DBDE0EE2D33A877FC583"),
            Data(hexString: "E2747D4E00C55D69FA0B8ADFAFD07F41144F888E322D377878E83F25FD2E258B2E918EF79E151337D7F3BD0798D66FDCE04B07C30984424B13344F0A7CC40168"),
        ]

        // when
        let (kaspaTransaction, hashes) = try txBuilder.buildForSign(transaction: transaction)
        let builtTransaction = txBuilder.mapToTransaction(transaction: kaspaTransaction, signatures: signatures)

        // then

        let expectedHashes = [
            Data(hex: "90b94d04bd7ebf0edada8230a3181176bddf017fd730020d2dfb7a2f8dbf03f3"),
        ]

        let expectedTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb",
                        index: 0
                    ),
                    signatureScript: "41e2747d4e00c55d69fa0b8adfafd07f41144f888e322d377878e83f25fd2e258b2e918ef79e151337d7f3bd0798d66fdce04b07c30984424b13344f0a7cc4016501"
                ),
            ],
            outputs: [
                .init(
                    amount: 100000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2060072bbddb7a7d1dbf40302ce04d51db49e223f8e5159fcce14143fd4be20328ac"
                    )
                ),
                .init(
                    amount: 9870000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2103eb30400ce9d1deed12b84d4161a1fa922ef4185a155ef3ec208078b3807b126fab"
                    )
                ),
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try encoder.encode(expectedTransaction)

        #expect(hashes == expectedHashes)
        #expect(encodedBuiltTransaction == encodedExpectedTransaction)
    }

    @Test
    func p2shTransaction() throws {
        // given
        let address = try KaspaAddressService(isTestnet: false).makeAddress(from: walletPublicKey)
        let unspentOutputManager: UnspentOutputManager = .kaspa(address: address)
        let outputs: [UnspentOutput] = [
            UnspentOutput(blockId: 2, txId: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a", index: 0, amount: 500000000),
        ]

        unspentOutputManager.update(
            outputs: outputs,
            // NOTE: Be careful that lockingScript is not same that we have for source address
            for: UTXOLockingScript(keyHash: Data(), data: Data(hexString: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"), type: .p2pk)
        )

        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: .empty,
            unspentOutputManager: unspentOutputManager,
            isTestnet: false
        )

        let destination = "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r"
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: Decimal(stringValue: "0.001")!),
            fee: Fee(Amount(with: blockchain, value: Decimal(stringValue: "0.0001")!)),
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        let signatures = [
            Data(hexString: "E2747D4E00C55D69FA0B8ADFAFD07F41144F888E322D377878E83F25FD2E258B2E918EF79E151337D7F3BD0798D66FDCE04B0704EB30400CE9D1DEED12B84D41"),
        ]

        // when
        let (kaspaTransaction, hashes) = try txBuilder.buildForSign(transaction: transaction)
        let builtTransaction = txBuilder.mapToTransaction(transaction: kaspaTransaction, signatures: signatures)

        // then
        let expectedHashes = [
            Data(hex: "C550515D34A091D7F3D2827286E7AEF685ECE9C0BBCCB4B08BC65F6EBD83E8F2"),
        ]

        let expectedTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a",
                        index: 0
                    ),
                    signatureScript: "41e2747d4e00c55d69fa0b8adfafd07f41144f888e322d377878e83f25fd2e258b2e918ef79e151337d7f3bd0798d66fdce04b0704eb30400ce9d1deed12b84d4101"
                ),
            ],
            outputs: [
                .init(
                    amount: 100000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "aa20383b73d107f9730f6c24bc5293240ac3b827e19e0e1bf4ef16852beb297222c587"
                    )
                ),
                .init(
                    amount: 499890000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2103eb30400ce9d1deed12b84d4161a1fa922ef4185a155ef3ec208078b3807b126fab"
                    )
                ),
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try encoder.encode(expectedTransaction)

        #expect(hashes == expectedHashes)
        #expect(encodedBuiltTransaction == encodedExpectedTransaction)
    }

    /// https://explorer.kaspa.org/txs/d36868e768d472a5ac2fc6f922c844bdbdda2bd0ef4626dd5e31d5f83e6c9223
    @Test
    func coinTransaction() throws {
        // given
        let address = PlainAddress(value: "kaspa:qyp5qxu7n45c8zx6pqhndy43p4qt02zxchc4723fuclpraty00gpm6c8edeys5s", publicKey: .empty, type: .default)
        let unspentOutputManager: UnspentOutputManager = .kaspa(address: address)
        let outputs: [UnspentOutput] = [
            UnspentOutput(blockId: 0, txId: "414f096361040f27e3ebfd02965c27d1492a69880dbf1544bf213e7159709134", index: 0, amount: 20000000),
            UnspentOutput(blockId: 0, txId: "5a2e80c8a279e52b87c6fe1503947e6bb0c081333f465f913d4a0245426109c7", index: 0, amount: 20000000),
            UnspentOutput(blockId: 1, txId: "c0414400517ec124d9e25531bf52cda241592ec4f89ff3e348f64c62900c461d", index: 1, amount: 39819474),
        ]

        unspentOutputManager.update(outputs: outputs, for: address)
        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: .init(seedKey: Data(hexString: "03401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01deb"), derivationType: .none),
            unspentOutputManager: unspentOutputManager,
            isTestnet: false
        )

        let destination = "kaspa:qypwtfhx630ujfau72akxgypfscdset2xe4v32j7xyyxw658glunexq9v4mmqhq"
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: Decimal(stringValue: "0.2")!),
            fee: Fee(Amount(with: blockchain, value: Decimal(stringValue: "0.00075342")!)),
            sourceAddress: address.value,
            destinationAddress: destination,
            changeAddress: address.value
        )

        let signatures = [
            Data(hexString: "b9e8176f4a914b6ade39994e548af271d8d04bd1c864e97cad9fd41f9757fcb1005ad38d0622cb7937e54da4d7a28fb2b45f2096e37ee37cf89e620287dccb07"),
        ]

        // when
        let (kaspaTransaction, hashes) = try txBuilder.buildForSign(transaction: transaction)
        let builtTransaction = txBuilder.mapToTransaction(transaction: kaspaTransaction, signatures: signatures)

        // then

        let expectedHashes = [
            Data(hex: "43ffd3b7abd1344e7e8a757c65e48e3639a93c4099a3f4e05daa6526061a7bcf"),
        ]

        let expectedTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "c0414400517ec124d9e25531bf52cda241592ec4f89ff3e348f64c62900c461d",
                        index: 1
                    ),
                    signatureScript: "41b9e8176f4a914b6ade39994e548af271d8d04bd1c864e97cad9fd41f9757fcb1005ad38d0622cb7937e54da4d7a28fb2b45f2096e37ee37cf89e620287dccb0701"
                ),
            ],
            outputs: [
                .init(
                    amount: 20000000,
                    scriptPublicKey: .init(
                        scriptPublicKey: "2102e5a6e6d45fc927bcf2bb6320814c30d8656a366ac8aa5e3108676a8747f93c98ab",
                        version: 0
                    )
                ),
                // Change
                .init(
                    amount: 19744132,
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

        #expect(hashes == expectedHashes)
        #expect(encodedBuiltTransaction == encodedExpectedTransaction)
    }

    /// https://explorer.kaspa.org/txs/c97e84228b68aa37a0c51c5a93f0005eb9543a353b6cf59c33052eab33f16e0b
    @Test
    func krc20TokenTransaction() throws {
        // given
        let address = PlainAddress(value: "kaspa:qyp5qxu7n45c8zx6pqhndy43p4qt02zxchc4723fuclpraty00gpm6c8edeys5s", publicKey: .empty, type: .default)
        let unspentOutputManager: UnspentOutputManager = .kaspa(address: address)
        let outputs: [UnspentOutput] = [
            UnspentOutput(blockId: 0, txId: "5a2e80c8a279e52b87c6fe1503947e6bb0c081333f465f913d4a0245426109c7", index: 0, amount: 20000000),
            UnspentOutput(blockId: 1, txId: "414f096361040f27e3ebfd02965c27d1492a69880dbf1544bf213e7159709134", index: 0, amount: 20000000),
            UnspentOutput(blockId: 2, txId: "d36868e768d472a5ac2fc6f922c844bdbdda2bd0ef4626dd5e31d5f83e6c9223", index: 1, amount: 19744132),
        ]

        unspentOutputManager.update(outputs: outputs, for: address)
        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: .init(seedKey: Data(hexString: "03401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01deb"), derivationType: .none),
            unspentOutputManager: unspentOutputManager,
            isTestnet: false
        )

        let token = Token(name: "GGMF", symbol: "GGMF", contractAddress: "GGMF", decimalCount: 8)
        let destination = "kaspa:qypwtfhx630ujfau72akxgypfscdset2xe4v32j7xyyxw658glunexq9v4mmqhq"
        let feeParams = KaspaKRC20.TokenTransactionFeeParams(
            commitFee: Amount(with: blockchain, value: Decimal(stringValue: "0.00003178")!),
            revealFee: Amount(with: blockchain, value: Decimal(stringValue: "0.000041")!)
        )

        let fee = Fee(
            Amount(with: blockchain, value: Decimal(stringValue: "0.00007278")!),
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
            Data(hexString: "c4af7290f10524058ca3e294700555f261f779555400eaa77faf5932d4376fb231cb92ea0b06a7b3bdbc65806366fbaca70e48de908f1d7aa5dc65a89ceea5bc"),
            Data(hexString: "415ac1b76db22f4a7265ddaa239954bb574373192d05943fe83a19c4bc7ea3684a0596eca3bc2b54affdd2ca83b2cecfe62c2debfb287be0e77ce88b237405a9"),
        ]

        let revealSignatures = [
            Data(hexString: "f6d895c542c586c952a16c46df41f2bbd1056e84a52ac18ecb809500b51c9db92b29a824999bcbbf800a262f472bb28db13c258e8ca09afd5cd8ec1ab1377f98"),
        ]

        let commitRedeemScript = Data(hexString: "2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab0063076b6173706c65785100004c8b7b22616d74223a22313030303030303030222c226f70223a227472616e73666572222c2270223a226b72632d3230222c227469636b223a2247474d46222c22746f223a226b617370613a7179707774666878363330756a6661753732616b7867797066736364736574327865347633326a377879797877363538676c756e6578713976346d6d716871227d68")

        // when
        let (txgroup, meta) = try txBuilder.buildForSignKRC20(transaction: transaction)
        let hashes = txgroup.hashesCommit + txgroup.hashesReveal
        let builtTransaction = txBuilder.mapToTransaction(transaction: txgroup.kaspaCommitTransaction, signatures: signatures)
        let builtRevealTransaction = txBuilder.mapToRevealTransaction(
            transaction: txgroup.kaspaRevealTransaction,
            commitRedeemScript: commitRedeemScript,
            signatures: revealSignatures
        )

        // then

        let expectedHashes = [
            Data(hex: "aae07366c0de5258af7b5a1b9b5fd5cfc8d07d1934945dc6205da1dc63d961f7"),
            Data(hex: "a19910d935a92efbfb0a99fcb98982c2dfd5d7a90998eed033d9fe62d2abf357"),
            Data(hex: "06ecad0c1d8efd05e62a0fa1fafc08c72d10495bf04cc6c13984b1102f2dfec7"),
        ]

        let expectedTransaction = KaspaDTO.Send.Request.Transaction(
            inputs: [
                .init(
                    previousOutpoint: .init(
                        transactionId: "5a2e80c8a279e52b87c6fe1503947e6bb0c081333f465f913d4a0245426109c7",
                        index: 0
                    ),
                    signatureScript: "41c4af7290f10524058ca3e294700555f261f779555400eaa77faf5932d4376fb231cb92ea0b06a7b3bdbc65806366fbaca70e48de908f1d7aa5dc65a89ceea5bc01"
                ),
                .init(
                    previousOutpoint: .init(
                        transactionId: "d36868e768d472a5ac2fc6f922c844bdbdda2bd0ef4626dd5e31d5f83e6c9223",
                        index: 1
                    ),
                    signatureScript: "41415ac1b76db22f4a7265ddaa239954bb574373192d05943fe83a19c4bc7ea3684a0596eca3bc2b54affdd2ca83b2cecfe62c2debfb287be0e77ce88b237405a901"
                ),
            ],
            outputs: [
                // Dust(0.2 KAS) + feeEstimationRevealTransactionValue(0.000041)
                .init(
                    amount: 20004100,
                    scriptPublicKey: .init(
                        scriptPublicKey: "aa20338345d892f8fb9066018754ac1d75cd8550ced29b55b4c9005d89a88f3e542a87",
                        version: 0
                    )
                ),
                // Change
                .init(
                    amount: 19736854,
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
                        transactionId: "5f7deb4c490de237e0dcc9dae4216f80247a671ca30eaab411d2963c6e070113",
                        index: 0
                    ),
                    signatureScript: "41f6d895c542c586c952a16c46df41f2bbd1056e84a52ac18ecb809500b51c9db92b29a824999bcbbf800a262f472bb28db13c258e8ca09afd5cd8ec1ab1377f98014cbe2103401b9e9d698388da082f3692b10d40b7a846c5f15f2a29e63e11f5647bd01debab0063076b6173706c65785100004c8b7b22616d74223a22313030303030303030222c226f70223a227472616e73666572222c2270223a226b72632d3230222c227469636b223a2247474d46222c22746f223a226b617370613a7179707774666878363330756a6661753732616b7867797066736364736574327865347633326a377879797877363538676c756e6578713976346d6d716871227d68"
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

        #expect(tx1.transactionId?.hexadecimal == "c2cb9d865f5085cd6f7f23365545c68d1eaca7e3cde9d231a64812be2c989a30")
        #expect(tx1.transactionHash?.hexadecimal == "06661f542544b166259af2e5dd01fc873a8893bf1aa4fada36fb92dfce64b4b0")
        #expect(tx2.transactionId?.hexadecimal == "d9cd38d294de5cce401330a91c97807b5433a377e043e99b66363fe5274477c9")
        #expect(tx2.transactionHash?.hexadecimal == "b5b1f2be9ec7dd34ee0da90addcae9bb7bbba145b1460ad639017059f9e41829")
    }
}

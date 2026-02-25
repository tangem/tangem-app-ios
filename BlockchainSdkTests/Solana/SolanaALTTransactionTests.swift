//
//  SolanaALTTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing
import SolanaSwift

struct SolanaALTTransactionTests {
    private let walletPublicKey = SolanaSwift.PublicKey(string: "H92WGLjfWPkGHLUAZfiuGpmVahJY6dFF8keQPbT6apcF")!

    ///
    @Test(arguments: ["0100080befc956a850e3dd3f49236e234b1f9ef97bc6bd4cc8f62a453790ffda215c1cd0821b8e94014ee6179f4f349149401a94a74d4281b05a970eac460873cceb87a4c76c5cd238bbbfb6dd0710fa4c2600927397d05613993c05683aac49d53f8eac00000000000000000000000000000000000000000000000000000000000000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590306466fe5211732ffecadba72c39be7bc8ce5bbc5f7126b2c439b3a40000000ce010e60afedb22717bd63192f54145a3f965a33bb82d2c7029eb2ce1e208264f3427828d631f9d2badf483574a565ca7cbb91f2a47ceb92f80e35774d7d1a3e069b8857feab8184fb687f634618c035dac439dc1aeb3b5598a0f0000000000106ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9075f6bf3d3f1b96038bd4fb6118f911f2e79e302f49be06db48d2625ce121a0adefd993aecf44c450683b40e5af4972eb6c0dd557c4cfcea6fde7c1081c16c0f0405000502a086010005000903e803000000000000040600010008030900070c030a0809020007060004070749181ec828051c0777e5234fbb00e1f50500000000b722f30000000000b722f3000000000027368368010000000000000100000000000000033683681800000020150000000001000000"])
    func testMessageLegacy(transaction: String) async throws {
        let transactionData = Data(hexString: transaction)
        let transaction: VersionedTransaction = try VersionedTransaction.deserialize(data: transactionData)

        guard case .legacy(let message) = transaction.message else {
            throw Error.transactionDecodeError
        }

        let lookupTableCreator = SolanaDummyALTLookupTableCreator(
            lookupTableAccountKey: "HZMD3eHQobUMmPCJ8uWa9ifGG2M478TSJwJmhu6c2ufM",
            lookupTableAccountDecodeState: Data(hexString: "7b226c617374457874656e646564536c6f74223a3335353630313539312c226c617374457874656e646564536c6f745374617274496e646578223a302c22616464726573736573223a5b2248393257474c6a6657506b47484c55415a66697547706d5661684a5936644646386b65515062543661706346222c223131313131313131313131313131313131313131313131313131313131313131222c2241546f6b656e47507662644756787231623268765a62736971573578574832356566544e734c4a41386b6e4c222c22436f6d70757465427564676574313131313131313131313131313131313131313131313131313131313131222c22484e6172667843336b594d4d68466b7855466559623877485664507a59357439707570715735664c326d654d222c22536f3131313131313131313131313131313131313131313131313131313131313131313131313131313132222c22546f6b656e6b65675166655a79694e77414a624e62474b5046584357754276663953733632335651354441225d2c22617574686f72697479223a2248393257474c6a6657506b47484c55415a66697547706d5661684a5936644646386b65515062543661706346222c2274797065496e646578223a312c22646561637469766174696f6e536c6f74223a31383434363734343037333730393535313631357d")
        )

        let blockhashProvider = SolanaDummyALTBlockhashProvider(dummyBlockhash: "HHnEdN5iDoa9xBQ7km25cDjE9GD9TgQF5QMLmATicmqN")
        let dummySignature = Data(hexString: "21978ac8afff90421f9dc964f0391464569d3f32abf92f7846b9c493ddb4fabdb5de6245210b3e1f78ae94a7e8552805ba30534016af3e3edd2c91fe9cb2e201")
        let sendBuilder = SolanaDummyALTSendTransactionBuilder(walletPublicKey: walletPublicKey, signature: dummySignature)

        var sender = SolanaALTLegacyTransactionSender(
            walletPublicKey: walletPublicKey,
            accountKeysSplitProvider: SolanaAccountKeysSplitUtils(),
            sendBuilder: sendBuilder,
            blockhashProvider: blockhashProvider,
            lookupTableCreator: lookupTableCreator
        )

        let buildForSend = try await sender.buildForSend(message: message)

        #expect(!buildForSend.isEmpty)
    }
}

extension SolanaALTTransactionTests {
    enum Error: Swift.Error {
        case transactionDecodeError
    }
}

struct SolanaTransactionHistoryMapperTests {
    private let blockchain = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)
    private let walletAddress = "WalletAddress1111111111111111111111111111111"
    private let destinationAddress = "DestinationAddress1111111111111111111111111"
    private let mintAddress = "Mint11111111111111111111111111111111111111"
    private let tokenSourceAddress = "TokenSource11111111111111111111111111111111"
    private let tokenDestinationAddress = "TokenDestination111111111111111111111111111"

    @Test
    func decodeSignatureItem() throws {
        let json = """
        {
          "blockTime": 1739362549,
          "confirmationStatus": "finalized",
          "err": null,
          "memo": null,
          "signature": "signature_1",
          "slot": 320159884
        }
        """

        let item = try decode(SolanaTransactionHistoryDTO.SignatureItem.self, from: json)
        #expect(item.signature == "signature_1")
        #expect(item.slot == 320159884)
    }

    @Test
    func mapCoinTransferTransaction() throws {
        let mapper = SolanaTransactionHistoryMapper(blockchain: blockchain)
        let details = try decode(
            SolanaTransactionHistoryDTO.TransactionDetails.self,
            from: """
            {
              "blockTime": 1739324168,
              "meta": {
                "err": null,
                "fee": 5000,
                "innerInstructions": [],
                "postBalances": [920796258, 987560],
                "preBalances": [920821258, 967560],
                "postTokenBalances": [],
                "preTokenBalances": [],
                "rewards": []
              },
              "slot": 320063016,
              "transaction": {
                "message": {
                  "accountKeys": [
                    { "pubkey": "\(walletAddress)" },
                    { "pubkey": "\(destinationAddress)" }
                  ],
                  "instructions": [
                    {
                      "parsed": {
                        "info": {
                          "destination": "\(destinationAddress)",
                          "lamports": 20000,
                          "source": "\(walletAddress)"
                        },
                        "type": "transfer"
                      },
                      "program": "system",
                      "programId": "11111111111111111111111111111111"
                    }
                  ]
                },
                "signatures": ["hash_1"]
              }
            }
            """
        )

        let records = try mapper.mapToTransactionRecords([details], walletAddress: walletAddress, amountType: .coin)
        #expect(records.count == 1)
        #expect(records[0].hash == "hash_1")
        #expect(records[0].type == .transfer)
        #expect(records[0].isOutgoing)
        #expect(records[0].fee.amount.value == Decimal(5000) / blockchain.decimalValue)
    }

    @Test
    func mapTokenOperationTransaction() throws {
        let mapper = SolanaTransactionHistoryMapper(blockchain: blockchain)
        let token = Token(
            name: "Test token",
            symbol: "TT",
            contractAddress: mintAddress,
            decimalCount: 0
        )

        let details = try decode(
            SolanaTransactionHistoryDTO.TransactionDetails.self,
            from: """
            {
              "blockTime": 1742895119,
              "meta": {
                "err": null,
                "fee": 5000,
                "innerInstructions": [],
                "postBalances": [1000, 2000],
                "preBalances": [6000, 2000],
                "postTokenBalances": [
                  {
                    "accountIndex": 0,
                    "mint": "\(mintAddress)",
                    "owner": "\(walletAddress)",
                    "uiTokenAmount": { "amount": "50", "decimals": 0, "uiAmountString": "50" }
                  }
                ],
                "preTokenBalances": [
                  {
                    "accountIndex": 0,
                    "mint": "\(mintAddress)",
                    "owner": "\(walletAddress)",
                    "uiTokenAmount": { "amount": "100", "decimals": 0, "uiAmountString": "100" }
                  }
                ],
                "rewards": []
              },
              "transaction": {
                "message": {
                  "accountKeys": [
                    { "pubkey": "\(walletAddress)" },
                    { "pubkey": "\(destinationAddress)" }
                  ],
                  "instructions": [
                    {
                      "parsed": {
                        "info": {
                          "source": "\(tokenSourceAddress)",
                          "destination": "\(tokenDestinationAddress)",
                          "amount": "50"
                        },
                        "type": "transfer"
                      },
                      "program": "spl-token",
                      "programId": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
                    }
                  ]
                },
                "signatures": ["hash_2"]
              }
            }
            """
        )

        let records = try mapper.mapToTransactionRecords(
            [details],
            walletAddress: walletAddress,
            amountType: .token(value: token)
        )

        #expect(records.count == 1)
        #expect(records[0].type == .contractMethodName(name: "operation"))
        #expect(records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: tokenSourceAddress, amount: 50)))
        #expect(records[0].destination == .single(.init(address: .user(tokenDestinationAddress), amount: 50)))
    }

    @Test
    func mapOtherOperationAsFailed() throws {
        let mapper = SolanaTransactionHistoryMapper(blockchain: blockchain)
        let details = try decode(
            SolanaTransactionHistoryDTO.TransactionDetails.self,
            from: """
            {
              "blockTime": 1716248162,
              "meta": {
                "err": { "InstructionError": [0, "custom"] },
                "fee": 15000,
                "innerInstructions": [],
                "postBalances": [5344795, 43789947],
                "preBalances": [5359795, 43789947],
                "postTokenBalances": [],
                "preTokenBalances": [],
                "rewards": []
              },
              "transaction": {
                "message": {
                  "accountKeys": [
                    { "pubkey": "\(walletAddress)" },
                    { "pubkey": "\(destinationAddress)" }
                  ],
                  "instructions": [
                    {
                      "parsed": {
                        "info": {
                          "stakeAccount": "\(destinationAddress)"
                        },
                        "type": "deactivate"
                      },
                      "program": "stake",
                      "programId": "Stake11111111111111111111111111111111111111"
                    }
                  ]
                },
                "signatures": ["hash_3"]
              }
            }
            """
        )

        let records = try mapper.mapToTransactionRecords([details], walletAddress: walletAddress, amountType: .coin)
        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .unstake, target: nil))
        #expect(records[0].status == .failed)
    }

    @Test
    func mapStakeOperationAsStake() throws {
        let mapper = SolanaTransactionHistoryMapper(blockchain: blockchain)
        let validatorAddress = "Validator11111111111111111111111111111111111"
        let details = try decode(
            SolanaTransactionHistoryDTO.TransactionDetails.self,
            from: """
            {
              "blockTime": 1771579635,
              "meta": {
                "err": null,
                "fee": 25000,
                "innerInstructions": [],
                "postBalances": [36523606, 20000000],
                "preBalances": [56548606, 0],
                "postTokenBalances": [],
                "preTokenBalances": [],
                "rewards": []
              },
              "transaction": {
                "message": {
                  "accountKeys": [
                    { "pubkey": "\(walletAddress)" },
                    { "pubkey": "\(destinationAddress)" }
                  ],
                  "instructions": [
                    {
                      "parsed": {
                        "info": {
                          "stakeAccount": "\(destinationAddress)",
                          "stakeAuthority": "\(walletAddress)",
                          "voteAccount": "\(validatorAddress)"
                        },
                        "type": "delegate"
                      },
                      "program": "stake",
                      "programId": "Stake11111111111111111111111111111111111111"
                    }
                  ]
                },
                "signatures": ["hash_4"]
              }
            }
            """
        )

        let records = try mapper.mapToTransactionRecords([details], walletAddress: walletAddress, amountType: .coin)
        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .stake, target: validatorAddress))
        #expect(records[0].isOutgoing)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: Data(json.utf8))
    }
}

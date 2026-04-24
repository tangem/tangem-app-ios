//
//  SolanaTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing
import SolanaSwift

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

    @Test
    func mapStakeOperationAsWithdraw() throws {
        let mapper = SolanaTransactionHistoryMapper(blockchain: blockchain)
        let stakeAccountAddress = "StakeAccount11111111111111111111111111111111"
        let details = try decode(
            SolanaTransactionHistoryDTO.TransactionDetails.self,
            from: """
            {
              "blockTime": 1771579735,
              "meta": {
                "err": null,
                "fee": 5000,
                "innerInstructions": [],
                "postBalances": [50000000, 0],
                "preBalances": [30000000, 0],
                "postTokenBalances": [],
                "preTokenBalances": [],
                "rewards": []
              },
              "transaction": {
                "message": {
                  "accountKeys": [
                    { "pubkey": "\(walletAddress)" },
                    { "pubkey": "\(stakeAccountAddress)" }
                  ],
                  "instructions": [
                    {
                      "parsed": {
                        "info": {
                          "destination": "\(walletAddress)",
                          "lamports": 20000000,
                          "source": "\(stakeAccountAddress)"
                        },
                        "type": "withdraw"
                      },
                      "program": "stake",
                      "programId": "Stake11111111111111111111111111111111111111"
                    }
                  ]
                },
                "signatures": ["hash_5"]
              }
            }
            """
        )

        let records = try mapper.mapToTransactionRecords([details], walletAddress: walletAddress, amountType: .coin)
        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .withdraw, target: nil))
        #expect(!records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: stakeAccountAddress, amount: 0.02)))
        #expect(records[0].destination == .single(.init(address: .user(walletAddress), amount: 0.02)))
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: Data(json.utf8))
    }
}

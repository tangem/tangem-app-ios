//
//  StakekitStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class StakekitStakingAPIService: StakingAPIService {
    let provider: MoyaProvider<StakekitTarget>

    init(provider: MoyaProvider<StakekitTarget>) {
        self.provider = provider
    }

    func getStakingInfo(wallet: any StakingWallet) async throws -> StakingInfo {}
}

private extension StakekitStakingAPIService {}

struct StakekitTarget: Moya.TargetType {
    let target: Target

    enum Target {
        case getAction(id: String)
//        case createAction()
    }

    var baseURL: URL {
        URL(string: "https://api.stakek.it")!
    }

    var path: String {}

    var method: Moya.Method {}

    var task: Moya.Task {}

    var headers: [String: String]? {
        ["X-API-KEY": "ccf0a87a-3d6a-41d0-afa4-3dfc1a101335"]
    }
}

// Polygon native
// ethereum-matic-native-staking
// 0x29010F8F91B980858EB298A0843264cfF21Fd9c9

enum StakekitDTO {
    // MARK: - Common

    struct Token: Codable {
        let network: String?
        let name: String?
        let decimals: Int?
        let address: String?
        let symbol: String?
        let logoURI: String?
    }

    struct Validator: Decodable {
        let address: String
        let status: Status
        let name: String?
        let image: String?
        let website: String?
        let apr: Double?
        let commission: Double?
        let stakedBalance: String?
        let votingPower: Double?
        let preferred: Bool?

        enum Status: String, Decodable {
            case active
            case jailed
            case deactivating
            case inactive
        }
    }

    enum Actions {
        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let addresses: [Address]
                let args: Args
                let integrationId: String

                struct Address: Encodable {
                    let address: String
                }

                struct Args: Encodable {
                    let inputToken: Token
                    let amount: String
                    let validatorAddress: String
                }
            }

            struct Response: Decodable {}
        }
    }

    enum Yield {
        enum Get {
            struct Request: Encodable {
                let integrationId: String
            }

            struct Response: Decodable {
                let id: String
                let token: Token
                let tokens: [Token]
                let args: Actions
                let status: Status
                let apy: Decimal
                let rewardRate: Decimal
                let rewardType: RewardType
                let metadata: Metadata
                let validators: [Validator]
                let isAvailable: Bool?

                struct Actions: Decodable {
                    let enter: Action<EnterActionArgs>
                    let exit: Action<ExitActionArgs>

                    struct Action<Args: Decodable>: Decodable {
                        let addresses: ActionAddresses?
                        let args: Args?

                        struct ActionAddresses: Decodable {
                            let address: Address?

                            struct Address: Decodable {
                                let required: Bool?
                                let network: String?
                            }
                        }

                        struct EnterActionArgs: Decodable {
                            let amount: Amount?
                            let validatorAddress: ValidatorAddress?

                            struct Amount: Decodable {
                                let required: Bool?
                                let minimum: Decimal?
                            }

                            struct ValidatorAddress: Decodable {
                                let required: Bool?
                            }
                        }

                        struct ExitActionArgs: Decodable {
                            let amount: Amount?
                            let validatorAddress: ValidatorAddress?

                            struct Amount: Decodable {
                                let required: Bool?
                                let minimum: Decimal?
                            }

                            struct ValidatorAddress: Decodable {
                                let required: Bool?
                            }
                        }
                    }
                }

                struct Status: Decodable {
                    let enter: Bool?
                    let exit: Bool?
                }

                enum RewardType: String, Decodable {
                    case apr
                    case apy
                    case variable
                }

                struct Metadata: Decodable {
                    let name: String
                    let logoURI: String?
                    let description: String?
                    let documentation: String?
                    let token: Token
                    let tokens: [Token]
                    let type: MetadataType
                    let rewardSchedule: RewardScheduleType
                    let cooldownPeriod: Period?
                    let warmupPeriod: Period
                    let withdrawPeriod: Period?
                    let rewardClaiming: RewardClaiming
                    let defaultValidator: String?
                    let supportsMultipleValidators: Bool?
                    let supportsLedgerWalletApi: Bool?
                    let revshare: Enabled
                    let fee: Enabled

                    enum MetadataType: String, Decodable {
                        case staking
                        case liquidStaking = "liquid-staking"
                        case lending, restaking, vault
                    }

                    enum RewardScheduleType: String, Decodable {
                        case block
                        case hour
                        case day
                        case week
                        case month
                        case era
                        case epoch
                    }

                    enum Period: Decodable {
                        case days(Int)
                    }

                    enum RewardClaiming: String, Decodable {
                        case auto
                        case manual
                    }

                    struct Enabled: Decodable {
                        let enabled: Bool
                    }
                }
            }
        }
    }
}

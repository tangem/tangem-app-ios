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

enum StakekitDTO {
    enum Actions {
        enum Get {
            struct Request: Encodable {
                let actionId: String
            }
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
                    let inputToken: InputToken?
                    let amount: String?
                }

                struct InputToken: Encodable {
                    let network: String?
                }
            }

            struct Response: Decodable {}
        }
    }
}

//
//  SolanaScaledUiAmountDTO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

enum SolanaScaledUiAmountDTO {
    struct GetAccountInfoResult: Decodable {
        let value: Value?

        struct Value: Decodable {
            let data: DataInfo?

            struct DataInfo: Decodable {
                let parsed: Parsed?

                struct Parsed: Decodable {
                    let info: Info?

                    struct Info: Decodable {
                        let extensions: [ExtensionInfo]

                        struct ExtensionInfo: Decodable {
                            let `extension`: String
                            let state: State?

                            struct State: Decodable {
                                let multiplier: String?
                                let newMultiplier: String?
                                let newMultiplierEffectiveTimestamp: Int64?
                            }
                        }

                        private enum CodingKeys: String, CodingKey {
                            case extensions
                        }

                        init(from decoder: Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            extensions = try container.decodeIfPresent([ExtensionInfo].self, forKey: .extensions) ?? []
                        }
                    }
                }
            }
        }
    }
}

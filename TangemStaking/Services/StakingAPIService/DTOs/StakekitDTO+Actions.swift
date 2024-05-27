//
//  StakekitDTO+Actions.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakekitDTO {
    // [REDACTED_TODO_COMMENT]
    enum Actions {
        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let addresses: Address
                let args: Args
                let integrationId: String

                struct Args: Encodable {
                    let amount: String
                    let validatorAddress: String?
                    let validatorAddresses: [Address]
                }
            }

            struct Response: Decodable {}
        }
    }
}

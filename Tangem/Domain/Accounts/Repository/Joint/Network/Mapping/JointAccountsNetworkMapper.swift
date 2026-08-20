//
//  JointAccountsNetworkMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct JointAccountsNetworkMapper {
    func mapToCreateRequest(from blob: JointAccountCreationBlob) -> JointAccountsDTO.Create.Request {
        JointAccountsDTO.Create.Request(
            payload: blob.payload,
            signature: blob.signature.hexString.addHexPrefix()
        )
    }
}

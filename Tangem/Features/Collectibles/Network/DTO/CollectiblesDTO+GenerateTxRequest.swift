//
//  CollectiblesDTO+GenerateTxRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    struct GenerateTxRequest: Encodable {
        let fromAddress, collectibleType, toAddress: String
        let turboMode: TurboMode?

        struct TurboMode: Encodable {
            let enabled: Bool
            let buybackAddress: String?
        }

        init(fromAddress: String, collectibleType: String, toAddress: String, turboMode: TurboMode? = nil) {
            self.fromAddress = fromAddress
            self.collectibleType = collectibleType
            self.toAddress = toAddress
            self.turboMode = turboMode
        }
    }
}

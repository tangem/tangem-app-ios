//
//  XPUBNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol XPUBNetworkProvider: HostProvider {
    func getInfo(xpub: String) -> AnyPublisher<XPUBInfo, Error>
}

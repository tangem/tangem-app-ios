//
//  P2PDelegatorAddressProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol P2PDelegatorAddressProvider {
    @MainActor
    func delegatorAddresses() -> [String]

    var delegatorAddressesPublisher: AnyPublisher<[String], Never> { get }
}

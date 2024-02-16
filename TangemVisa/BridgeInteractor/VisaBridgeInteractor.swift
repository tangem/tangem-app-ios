//
//  VisaBridgeInteractor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

public protocol VisaBridgeInteractor {
    var accountAddress: String { get }
    func loadBalances() async throws -> VisaBalances
    func loadLimits() async throws -> VisaLimits
}

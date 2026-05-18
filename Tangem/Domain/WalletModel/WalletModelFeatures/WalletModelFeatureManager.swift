//
//  WalletModelFeatureManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletModelFeatureManager<Payload>: AnyObject, Sendable {
    associatedtype Payload

    var featurePayload: Payload? { get }
    var featurePayloadPublisher: AnyPublisher<Payload?, Never> { get }
}

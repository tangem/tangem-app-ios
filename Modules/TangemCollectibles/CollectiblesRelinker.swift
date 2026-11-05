//
//  CollectiblesRelinker.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol CollectiblesRelinker: AnyObject {
    func relink() async throws -> CollectiblesRelinkOutcome
}

public enum CollectiblesRelinkOutcome: Equatable, Sendable {
    case relinked
    case accountNotFound
}

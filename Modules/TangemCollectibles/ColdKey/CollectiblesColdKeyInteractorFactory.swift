//
//  CollectiblesColdKeyInteractorFactory.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Warning: A long-lived holder must keep the factory rather than an interactor, which freezes the session filter
/// and the SDK configuration it was made with.
public protocol CollectiblesColdKeyInteractorFactory {
    func makeInteractor() -> CollectiblesColdKeyInteractor
}

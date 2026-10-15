//
//  CommonCollectiblesColdKeyInteractorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles

final class CommonCollectiblesColdKeyInteractorFactory {
    private weak var interactorProvider: (any CollectiblesColdKeyInteractorProvider)?

    init(interactorProvider: (any CollectiblesColdKeyInteractorProvider)? = nil) {
        self.interactorProvider = interactorProvider
    }

    func configure(with interactorProvider: any CollectiblesColdKeyInteractorProvider) {
        self.interactorProvider = interactorProvider
    }
}

// MARK: - CollectiblesColdKeyInteractorFactory protocol conformance

extension CommonCollectiblesColdKeyInteractorFactory: CollectiblesColdKeyInteractorFactory {
    func makeInteractor() -> CollectiblesColdKeyInteractor {
        interactorProvider?.collectiblesColdKeyInteractor ?? UnavailableCollectiblesColdKeyInteractor()
    }
}

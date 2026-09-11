//
//  CollectiblesEntranceCardView+Factory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesEntranceCardView {
    static func make(onOpenRequested: @MainActor @escaping (CollectiblesCoordinator.Options) -> Void) -> CollectiblesEntranceCardView {
        CollectiblesEntranceCardView(userWalletModelsProvider: InjectedValues[\.userWalletRepository].models, onOpenRequested: onOpenRequested)
    }
}

//
//  GachaEntranceCardView+Factory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension GachaEntranceCardView {
    static func make(onOpenRequested: @MainActor @escaping (GachaCoordinator.Options) -> Void) -> GachaEntranceCardView {
        GachaEntranceCardView(userWalletModelsProvider: InjectedValues[\.userWalletRepository].models, onOpenRequested: onOpenRequested)
    }
}

//
//  PromoPageStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol PromoPageStorage: AnyObject {
    var pendingPage: String? { get set }
}

final class CommonPromoPageStorage: PromoPageStorage {
    var pendingPage: String? {
        get { AppSettings.shared.pendingPromoPage }
        set { AppSettings.shared.pendingPromoPage = newValue }
    }
}

// MARK: - Injection

private struct PromoPageStorageKey: InjectionKey {
    static var currentValue: PromoPageStorage = CommonPromoPageStorage()
}

extension InjectedValues {
    var promoPageStorage: PromoPageStorage {
        get { Self[PromoPageStorageKey.self] }
        set { Self[PromoPageStorageKey.self] = newValue }
    }
}

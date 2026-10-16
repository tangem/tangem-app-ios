//
//  TangemPayCampaignKeyStorage.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol TangemPayCampaignKeyStorage: AnyObject {
    var pendingCampaignKey: String? { get set }
    var pendingCampaignKeyPublisher: AnyPublisher<String?, Never> { get }
}

final class CommonTangemPayCampaignKeyStorage: TangemPayCampaignKeyStorage {
    var pendingCampaignKey: String? {
        get { AppSettings.shared.pendingTangemPayCampaignKey }
        set { AppSettings.shared.pendingTangemPayCampaignKey = newValue }
    }

    var pendingCampaignKeyPublisher: AnyPublisher<String?, Never> {
        AppSettings.shared.$pendingTangemPayCampaignKey.eraseToAnyPublisher()
    }
}

// MARK: - Injection

private struct TangemPayCampaignKeyStorageKey: InjectionKey {
    static var currentValue: TangemPayCampaignKeyStorage = CommonTangemPayCampaignKeyStorage()
}

extension InjectedValues {
    var tangemPayCampaignKeyStorage: TangemPayCampaignKeyStorage {
        get { Self[TangemPayCampaignKeyStorageKey.self] }
        set { Self[TangemPayCampaignKeyStorageKey.self] = newValue }
    }
}

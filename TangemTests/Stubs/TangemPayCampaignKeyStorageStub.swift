//
//  TangemPayCampaignKeyStorageStub.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
@testable import Tangem

final class TangemPayCampaignKeyStorageStub: TangemPayCampaignKeyStorage {
    private let subject: CurrentValueSubject<String?, Never>

    init(pendingCampaignKey: String? = nil) {
        subject = CurrentValueSubject(pendingCampaignKey)
    }

    var pendingCampaignKey: String? {
        get { subject.value }
        set { subject.send(newValue) }
    }

    var pendingCampaignKeyPublisher: AnyPublisher<String?, Never> {
        subject.eraseToAnyPublisher()
    }
}

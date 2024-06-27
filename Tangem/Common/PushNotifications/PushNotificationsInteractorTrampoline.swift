//
//  PushNotificationsInteractorTrampoline.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class PushNotificationsInteractorTrampoline {
    typealias IsAvailable = () async -> Bool
    typealias AllowRequest = () -> Void
    typealias PostponeRequest = AllowRequest

    private let _isAvailable: IsAvailable
    private let _allowRequest: AllowRequest
    private let _postponeRequest: PostponeRequest

    internal init(
        isAvailable: @escaping IsAvailable,
        allowRequest: @escaping AllowRequest,
        postponeRequest: @escaping PostponeRequest
    ) {
        _isAvailable = isAvailable
        _allowRequest = allowRequest
        _postponeRequest = postponeRequest
    }
}

// MARK: - PushNotificationsInteractor protocol conformance

extension PushNotificationsInteractorTrampoline: PushNotificationsInteractor {
    var isAvailable: Bool {
        get async {
            return await _isAvailable()
        }
    }

    func allowRequest() {
        _allowRequest()
    }

    func postponeRequest() {
        _postponeRequest()
    }
}

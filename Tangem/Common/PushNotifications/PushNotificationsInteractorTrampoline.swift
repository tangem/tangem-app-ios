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
    typealias CanPostponePermissionRequest = () -> Bool
    typealias AllowRequest = () async -> Void
    typealias PostponeRequest = () -> Void

    private let _isAvailable: IsAvailable
    private let _canPostponePermissionRequest: CanPostponePermissionRequest
    private let _allowRequest: AllowRequest
    private let _postponeRequest: PostponeRequest

    internal init(
        isAvailable: @escaping IsAvailable,
        canPostponePermissionRequest: @escaping CanPostponePermissionRequest,
        allowRequest: @escaping AllowRequest,
        postponeRequest: @escaping PostponeRequest
    ) {
        _isAvailable = isAvailable
        _canPostponePermissionRequest = canPostponePermissionRequest
        _allowRequest = allowRequest
        _postponeRequest = postponeRequest
    }
}

// MARK: - PushNotificationsAvailabilityProvider protocol conformance

extension PushNotificationsInteractorTrampoline: PushNotificationsAvailabilityProvider {
    var isAvailable: Bool {
        get async {
            return await _isAvailable()
        }
    }
}

// MARK: - PushNotificationsPermissionManager protocol conformance

extension PushNotificationsInteractorTrampoline: PushNotificationsPermissionManager {
    var canPostponePermissionRequest: Bool {
        _canPostponePermissionRequest()
    }

    func allowPermissionRequest() async {
        await _allowRequest()
    }

    func postponePermissionRequest() {
        _postponeRequest()
    }
}

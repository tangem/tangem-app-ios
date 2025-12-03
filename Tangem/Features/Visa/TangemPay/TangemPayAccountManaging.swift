//
//  TangemPayAccountManaging.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum TangemPayAccountManagingState: Equatable {
    case idle
    case unavailable
    case offered(TangemPayStatus)
    case syncNeeded
    case activated(TangemPayAccount)

    var account: TangemPayAccount? {
        switch self {
        case .activated(let acc):
            return acc

        default:
            return nil
        }
    }
}

protocol TangemPayAccountManaging: AnyObject, TangemPayAccountProvider, TangemPayAuthorizingProvider {
    var statePublisher: AnyPublisher<TangemPayAccountManagingState, Never> { get }
    var notificationManager: TangemPayNotificationManager { get }

    func onTangemPayOfferAccepted(_ onFinish: @escaping () -> Void) async throws
    func onTangemPaySync()

    @discardableResult
    func loadCustomerInfo() -> Task<Void, Never>
    func freeze(cardId: String) async throws
    func unfreeze(cardId: String) async throws
    func launchKYC() async throws
}

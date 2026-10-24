//
//  TangemPayVirtualAccountCreationFailureStorage.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol TangemPayVirtualAccountCreationFailureStorage {
    func virtualAccountCreationFailedPublisher(customerWalletId: String) -> AnyPublisher<Bool, Never>
    func setVirtualAccountCreationFailed(_ isFailed: Bool, customerWalletId: String)
}

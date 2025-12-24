//
//  TangemPayAccountProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemVisa

// [REDACTED_TODO_COMMENT]
// Remove it and setup it before UserWalletModel was created
protocol TangemPayAccountProviderSetupable: TangemPayAccountProvider {
    func setup(for userWalletModel: any UserWalletModel)
}

protocol TangemPayAccountProvider {
    var paeraCustomer: PaeraCustomer? { get }
    var paeraCustomerPublisher: AnyPublisher<PaeraCustomer?, Never> { get }
}

class CommonTangemPayAccountProvider {
    private let paeraCustomerSubject: CurrentValueSubject<PaeraCustomer?, Never> = .init(nil)
    private var paeraCustomerCancellable: Cancellable?

    init() {}
}

// MARK: - TangemPayAccountProvider

extension CommonTangemPayAccountProvider: TangemPayAccountProviderSetupable {
    func setup(for userWalletModel: any UserWalletModel) {
        Task { [self] in
            let paeraCustomer = await PaeraCustomerBuilder(userWalletModel: userWalletModel).getIfExist()

            if let paeraCustomer {
                paeraCustomerSubject.send(paeraCustomer)
            } else {
                // Make it possible to create PaeraCustomer from offer screen
                paeraCustomerCancellable = userWalletModel.updatePublisher
                    .compactMap(\.paeraCustomer)
                    .first()
                    .sink(receiveValue: paeraCustomerSubject.send)
            }
        }
    }
}

// MARK: - TangemPayAccountProvider

extension CommonTangemPayAccountProvider: TangemPayAccountProvider {
    var paeraCustomer: PaeraCustomer? {
        paeraCustomerSubject.value
    }

    var paeraCustomerPublisher: AnyPublisher<PaeraCustomer?, Never> {
        paeraCustomerSubject.eraseToAnyPublisher()
    }
}

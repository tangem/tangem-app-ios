//
//  TangemPayIssuingManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol TangemPayIssuingManagerDelegate: AnyObject {
    func createAccountAndIssueCard()
}

final class TangemPayIssuingManager {
    private weak var delegate: TangemPayIssuingManagerDelegate?
    private var cancellable: Cancellable?

    init(
        tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never>,
        tangemPayCardIssuingPublisher: AnyPublisher<Bool, Never>
    ) {
        cancellable = tangemPayStatusPublisher
            .prefix(
                untilOutputFrom: tangemPayCardIssuingPublisher.filter { $0 }
            )
            .filter { $0 == .readyToIssueOrIssuing }
            .prefix(1)
            .mapToVoid()
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.delegate?.createAccountAndIssueCard()
            }
    }

    func setupDelegate(_ delegate: TangemPayIssuingManagerDelegate) {
        self.delegate = delegate
    }
}

//
//  CommonHotNotificationsController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonHotNotificationsController {
    private let userWalletModel: UserWalletModel

    private let showFinishActivationNotificationSubject = CurrentValueSubject<Bool, Never>(false)

    private var bag = Set<AnyCancellable>()

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        bind()
    }
}

// MARK: - Private methods

private extension CommonHotNotificationsController {
    func bind() {
        // [REDACTED_TODO_COMMENT]
        showFinishActivationNotificationSubject.send(true)
    }
}

// MARK: - HotNotificationsController

extension CommonHotNotificationsController: HotNotificationsController {
    var showFinishActivationNotificationPublisher: AnyPublisher<Bool, Never> {
        showFinishActivationNotificationSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

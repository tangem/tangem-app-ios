//
//  CommonReferralNotificationController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonReferralNotificationController {
    private let userWalletModel: UserWalletModel
    private let showReferralNotificationSubject: CurrentValueSubject<Bool?, Never> = .init(nil)

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var cancellable: AnyCancellable?
    private var loadReferralTask: Task<ReferralProgramInfo, Error>?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel

        bind()
    }
}

extension CommonReferralNotificationController: ReferralNotificationController {
    var showReferralNotificationPublisher: AnyPublisher<Bool?, Never> {
        showReferralNotificationSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func checkReferralStatus() {
        guard AppSettings.shared.showReferralProgramOnMain,
              !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden else {
            return
        }

        TangemFoundation.runTask(in: self) { controller in
            do {
                let programInfo = try await controller.loadReferralProgram()
                controller.showReferralNotificationSubject.send(false) // [REDACTED_TODO_COMMENT]
            } catch {
                controller.showReferralNotificationSubject.send(true)
            }
        }
    }

    func dismissReferralNotification() {
        AppSettings.shared.showReferralProgramOnMain = false
    }
}

private extension CommonReferralNotificationController {
    func bind() {
        cancellable = AppSettings.shared.$showReferralProgramOnMain
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.showReferralNotificationSubject.send(nil)
            }
    }

    private func loadReferralProgram() async throws -> ReferralProgramInfo {
        if let loadReferralTask {
            return try await loadReferralTask.value
        }

        let task: Task<ReferralProgramInfo, Error> = Task { [weak self] in
            guard let self else { throw CancellationError() }

            return try await tangemApiService.loadReferralProgramInfo(
                for: userWalletModel.userWalletId.stringValue,
                expectedAwardsLimit: Constants.expectedAwardsLimit
            )
        }

        loadReferralTask = task

        return try await task.value
    }
}

private extension CommonReferralNotificationController {
    enum Constants {
        static let expectedAwardsLimit = 30
    }
}

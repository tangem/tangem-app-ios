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

        runTask(in: self) { controller in
            do {
                let programInfo = try await controller.loadReferralProgram()
                controller.showReferralNotificationSubject.send(programInfo.referral == nil)
            } catch {
                controller.showReferralNotificationSubject.send(false)
            }
        }
    }

    func dismissReferralNotification() {
        Analytics.log(.mainReferralProgramButtonDismiss)
        AppSettings.shared.showReferralProgramOnMain = false
    }
}

private extension CommonReferralNotificationController {
    func bind() {
        cancellable = AppSettings.shared.$showReferralProgramOnMain
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.showReferralNotificationSubject.send(false)
            }
    }

    @MainActor
    private func loadReferralProgram() async throws -> ReferralProgramInfo {
        if let loadReferralTask {
            return try await loadReferralTask.value
        }

        let task: Task<ReferralProgramInfo, Error> = Task { @MainActor [weak self] in
            guard let self else { throw CancellationError() }

            defer {
                loadReferralTask = nil
            }

            return try await tangemApiService.loadReferralProgramInfo(
                for: userWalletModel.userWalletId.stringValue,
                expectedAwardsLimit: ReferralConstants.expectedAwardsFetchLimit
            )
        }

        loadReferralTask = task

        return try await task.value
    }
}

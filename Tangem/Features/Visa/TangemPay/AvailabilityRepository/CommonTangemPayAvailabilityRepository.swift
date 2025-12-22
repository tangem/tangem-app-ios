//
//  CommonTangemPayAvailabilityRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemVisa

final class CommonTangemPayAvailabilityRepository: TangemPayAvailabilityRepository {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private var _availableUserWalletModels = CurrentValueSubject<[UserWalletModel], Never>([])
    private var _isTangemPayAvailable = CurrentValueSubject<Bool, Never>(false)
    private var _shouldShowGetTangemPayBanner = CurrentValueSubject<Bool, Never>(
        AppSettings.shared.tangemPayShouldShowGetBanner
    )

    var isTangemPayAvailablePublisher: AnyPublisher<Bool, Never> {
        _isTangemPayAvailable
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var availableUserWalletModels: [UserWalletModel] {
        _availableUserWalletModels.value
    }

    var isDeviceRooted: Bool {
        RTCUtil().checkStatus().hasIssues
    }

    var availableUserWalletModelsPublisher: AnyPublisher<[UserWalletModel], Never> {
        _availableUserWalletModels
            .eraseToAnyPublisher()
    }

    var isUserWalletModelsAvailble: AnyPublisher<Bool, Never> {
        availableUserWalletModelsPublisher
            .map { $0.isNotEmpty }
            .eraseToAnyPublisher()
    }

    var isTangemPayAvailable: Bool {
        _isTangemPayAvailable.value
    }

    var shouldShowGetTangemPayBanner: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest(
                shouldShowGetTangemPay,
                _shouldShowGetTangemPayBanner.eraseToAnyPublisher()
            )
            .map { $0 && $1 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest3(
                isTangemPayAvailablePublisher,
                isUserWalletModelsAvailble,
                Just(isDeviceRooted).map { !$0 }
            )
            .map { $0 && $1 && $2 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let availabilityService = TangemPayAPIServiceBuilder()
        .buildTangemPayAvailabilityService()

    private var cancellable: Cancellable?

    init() {
        // [REDACTED_TODO_COMMENT]
//        runTask(in: self) { repository in
//            do {
//                let isTangemPayAvailable = try await availabilityService
//                    .loadEligibility()
//                    .isTangemPayAvailable
//
//                self._isTangemPayAvailable.send(isTangemPayAvailable)
//            } catch {
//                VisaLogger.error("Failed to receive TangemPay availability", error: error)
//            }
//        }

        bind()
    }

    func userDidCloseGetTangemPayBanner() {
        _shouldShowGetTangemPayBanner.send(false)
        AppSettings.shared.tangemPayShouldShowGetBanner = false
    }

    private func bind() {
        cancellable = userWalletRepository.eventProvider
            .removeDuplicates()
            .mapToVoid()
            .prepend(())
            .withWeakCaptureOf(self)
            .asyncMap { repository, _ in
                return await repository.userWalletRepository.models
                    .asyncFilter { model in
                        guard !model.isUserWalletLocked, model.config.hasFeature(.tangemPay) else {
                            return false
                        }

                        do {
                            _ = try await repository.availabilityService
                                .isPaeraCustomer(
                                    customerWalletId: model.userWalletId.stringValue
                                )
                            return false
                        } catch {
                            return true
                        }
                    }
            }
            .sink(receiveValue: { [weak self] in
                self?._availableUserWalletModels.send($0)
            })
    }
}

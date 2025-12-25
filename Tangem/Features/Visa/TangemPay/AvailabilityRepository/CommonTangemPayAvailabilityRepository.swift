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

    var isUserWalletModelsAvailable: Bool {
        _availableUserWalletModels.value.isNotEmpty
    }

    var isUserWalletModelsAvailblePublisher: AnyPublisher<Bool, Never> {
        availableUserWalletModelsPublisher
            .map { $0.isNotEmpty }
            .eraseToAnyPublisher()
    }

    var isTangemPayAvailable: Bool {
        _isTangemPayAvailable.value
    }

    var shouldShowGetTangemPayBanner: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest3(
                shouldShowGetTangemPay,
                isTangemPayHiddenAnywhereOnce.map { !$0 },
                _shouldShowGetTangemPayBanner
            )
            .map { $0 && $1 && $2 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isTangemPayHiddenPublisher: AnyPublisher<[String: Bool], Never> {
        AppSettings.shared
            .$tangemPayIsKYCHiddenForCustomerWalletId
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isTangemPayHiddenAnywhereOnce: AnyPublisher<Bool, Never> {
        isTangemPayHiddenPublisher
            .map { $0.contains(where: { $0.value }) }
            .eraseToAnyPublisher()
    }

    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest4(
                isTangemPayAvailablePublisher,
                isUserWalletModelsAvailblePublisher,
                Just(isDeviceRooted).map { !$0 },
                Just(FeatureProvider.isAvailable(.tangemPayPermanentEntryPoint))
            )
            .map { $0 && $1 && $2 && $3 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let availabilityService = TangemPayAPIServiceBuilder()
        .buildTangemPayAvailabilityService()

    private var cancellable: Cancellable?

    init() {
        bind()

        guard FeatureProvider.isAvailable(.tangemPayPermanentEntryPoint) else {
            return
        }
        runTask(in: self) { repository in
            do {
                let isTangemPayAvailable = try await repository.availabilityService
                    .loadEligibility()
                    .isTangemPayAvailable

                repository._isTangemPayAvailable.send(isTangemPayAvailable)
            } catch {
                VisaLogger.error("Failed to receive TangemPay availability", error: error)
            }
        }
    }

    func userDidCloseGetTangemPayBanner() {
        _shouldShowGetTangemPayBanner.send(false)
        AppSettings.shared.tangemPayShouldShowGetBanner = false
    }

    func isTangemPayHiddenPublisher(for userWalletId: String) -> AnyPublisher<Bool, Never> {
        isTangemPayHiddenPublisher
            .map {
                $0[userWalletId, default: false]
            }
            .eraseToAnyPublisher()
    }

    private func bind() {
        let userWalletRepoEvent = userWalletRepository.eventProvider
            .removeDuplicates()
            .mapToVoid()
            .prepend(())

        cancellable = Publishers
            .CombineLatest(
                userWalletRepoEvent,
                isTangemPayHiddenPublisher
            )
            .mapToVoid()
            .withWeakCaptureOf(self)
            .asyncMap { repository, _ in
                return await repository.userWalletRepository.models
                    .asyncFilter { model in
                        guard !model.isUserWalletLocked, model.config.hasFeature(.tangemPay) else {
                            return false
                        }
                        let customerWalletId = model.userWalletId.stringValue

                        do {
                            let result = try await repository.availabilityService
                                .isPaeraCustomer(
                                    customerWalletId: customerWalletId
                                )

                            return !result.isTangemPayEnabled
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

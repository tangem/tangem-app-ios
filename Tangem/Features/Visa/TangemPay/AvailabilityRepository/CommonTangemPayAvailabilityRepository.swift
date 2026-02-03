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
import TangemPay

final class CommonTangemPayAvailabilityRepository: TangemPayAvailabilityRepository {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
    private var _availableUserWalletModels = CurrentValueSubject<[UserWalletModel], Never>([])

    var isTangemPayAvailablePublisher: AnyPublisher<Bool, Never> {
        AppSettings.shared
            .$tangemPayIsEligibilityAvailable
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

    var isUserWalletModelsAvailablePublisher: AnyPublisher<Bool, Never> {
        availableUserWalletModelsPublisher
            .map { $0.isNotEmpty }
            .eraseToAnyPublisher()
    }

    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest4(
                isTangemPayAvailablePublisher,
                isUserWalletModelsAvailablePublisher,
                Just(isDeviceRooted).map { !$0 },
                Just(FeatureProvider.isAvailable(.tangemPayPermanentEntryPoint))
            )
            .map { $0 && $1 && $2 && $3 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isTangemPayHiddenAnywhereOnce: AnyPublisher<Bool, Never> {
        AppSettings.shared
            .$tangemPayIsKYCHiddenForCustomerWalletId
            .removeDuplicates()
            .map { $0.contains(where: { $0.value }) }
            .eraseToAnyPublisher()
    }

    private let availabilityService = TangemPayAvailabilityServiceBuilder().build()

    private var bag = Set<AnyCancellable>()

    init() {
        bind()

        guard FeatureProvider.isAvailable(.tangemPayPermanentEntryPoint) else {
            return
        }

        if !AppSettings.shared.tangemPayIsEligibilityAvailable {
            runTask(in: self) { repo in
                await repo.requestEligibility()
            }
        }
    }

    func shouldShowGetTangemPayBanner(for customerWalletId: String) -> AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest3(
                shouldShowGetTangemPay,
                isTangemPayHiddenAnywhereOnce.map { !$0 },
                availableUserWalletModelsPublisher
                    .map { $0.contains(where: { $0.userWalletId.stringValue == customerWalletId }) }
            )
            .map { $0 && $1 && $2 }
            .eraseToAnyPublisher()
    }

    func userDidCloseGetTangemPayBanner() {
        AppSettings.shared.tangemPayShouldShowGetBanner = false
    }

    @discardableResult
    func requestEligibility() async -> Bool {
        do {
            let isTangemPayAvailable = try await availabilityService
                .loadEligibility()
                .isTangemPayAvailable

            if isTangemPayAvailable {
                await MainActor.run {
                    AppSettings.shared.tangemPayIsEligibilityAvailable = true
                }
            }

            return isTangemPayAvailable
        } catch {
            VisaLogger.error("Failed to receive TangemPay availability", error: error)
            return false
        }
    }

    private func isAvailableForTangemPay(
        userWalletModel: UserWalletModel
    ) async -> Bool {
        guard userWalletModel.supportsTangemPay else { return false }
        let customerWalletId = userWalletModel.userWalletId.stringValue

        if await AppSettings.shared.tangemPayIsPaeraCustomer[
            customerWalletId, default: false
        ] {
            return false
        }

        do {
            let result = try await availabilityService
                .isPaeraCustomer(
                    customerWalletId: customerWalletId
                )

            if result.isTangemPayEnabled {
                await MainActor.run {
                    AppSettings.shared.tangemPayIsPaeraCustomer[
                        customerWalletId
                    ] = true
                }
            }

            return !result.isTangemPayEnabled
        } catch {
            return true
        }
    }

    private func bind() {
        userWalletRepository.eventProvider
            .compactMap { $0.requestPaeraCustomerId }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .asyncMap { repo, id in
                guard let userWalletModel = repo.userWalletRepository.models.first(where: { $0.userWalletId == id }) else {
                    return
                }

                _ = await repo.isAvailableForTangemPay(userWalletModel: userWalletModel)
            }
            .sink()
            .store(in: &bag)

        let anyWalletModelChangingPublisher = userWalletRepository
            .eventProvider
            .mapToVoid()
            .withWeakCaptureOf(self)
            .flatMapLatest { repository, _ in
                let publishers = repository.userWalletRepository.models
                    .map { $0.updatePublisher.mapToVoid() }

                return Publishers
                    .MergeMany(
                        publishers
                    )
            }

        Publishers
            .CombineLatest3(
                userWalletRepository.eventProvider
                    .mapToVoid()
                    .prepend(()),
                anyWalletModelChangingPublisher.prepend(()),
                AppSettings.shared.$tangemPayIsPaeraCustomer
            )
            .map { $2 }
            .withWeakCaptureOf(self)
            .compactMap { repository, dictionary in
                let ids = dictionary
                    .filter { $0.value }
                    .map { $0.key }
                    .map { $0 }

                return repository.userWalletRepository.models
                    .filter {
                        $0.supportsTangemPay
                            && !ids.contains($0.userWalletId.stringValue)
                    }
            }
            .sink(receiveValue: { [weak self] in
                self?._availableUserWalletModels.send($0)
            })
            .store(in: &bag)
    }
}

// MARK: - Private utils

private extension UserWalletRepositoryEvent {
    var requestPaeraCustomerId: UserWalletId? {
        switch self {
        case .selected(let id), .inserted(let id):
            return id
        default:
            return nil
        }
    }
}

private extension UserWalletModel {
    var supportsTangemPay: Bool {
        !isUserWalletLocked && config.hasFeature(.tangemPay)
    }
}

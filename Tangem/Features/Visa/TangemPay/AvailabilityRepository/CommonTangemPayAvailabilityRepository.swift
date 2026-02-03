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

    private var _tangemPayOfferAvailabilitySubject = CurrentValueSubject<
        TangemPayOfferAvailability, Never
    >(.notAvailable)

    private var _tangemPayOfferAvailabilityPublisher: AnyPublisher<TangemPayOfferAvailability, Never> {
        _tangemPayOfferAvailabilitySubject
            .eraseToAnyPublisher()
    }

    var tangemPayOfferAvailability: TangemPayOfferAvailability {
        _tangemPayOfferAvailabilitySubject.value
    }

    var isTangemPayOfferAvailablePublisher: AnyPublisher<Bool, Never> {
        _tangemPayOfferAvailabilityPublisher
            .map { $0.isAvailable }
            .filter { $0 }
            .eraseToAnyPublisher()
    }

    var isTangemPayEligiblePublisher: AnyPublisher<Bool, Never> {
        AppSettings.shared
            .$tangemPayIsEligibilityAvailable
            .eraseToAnyPublisher()
    }

    private var isDeviceRooted: Bool {
        RTCUtil().checkStatus().hasIssues
    }

    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest4(
                isTangemPayEligiblePublisher,
                isTangemPayOfferAvailable,
                Just(isDeviceRooted).map { !$0 },
                Just(FeatureProvider.isAvailable(.tangemPayPermanentEntryPoint))
            )
            .map { $0 && $1 && $2 && $3 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var isTangemPayOfferAvailable: AnyPublisher<Bool, Never> {
        _tangemPayOfferAvailabilityPublisher
            .map { $0.isAvailable }
            .eraseToAnyPublisher()
    }

    private var isTangemPayHiddenAnywhereOnce: AnyPublisher<Bool, Never> {
        AppSettings.shared
            .$tangemPayIsKYCHiddenForCustomerWalletId
            .removeDuplicates()
            .map { $0.contains(where: { $0.value }) }
            .eraseToAnyPublisher()
    }

    private var wasAnyTangemPayOfferAccepted: AnyPublisher<Bool, Never> {
        AppSettings.shared
            .$tangemPayIsPaeraCustomer
            .removeDuplicates()
            .map { $0.contains(where: { $0.value }) }
            .eraseToAnyPublisher()
    }

    private var shouldShowTangemPayBannerByAppSettings: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest3(
                AppSettings.shared.$tangemPayShouldShowGetBanner,
                isTangemPayHiddenAnywhereOnce.map { !$0 },
                wasAnyTangemPayOfferAccepted.map { !$0 }
            )
            .map { $0 && $1 && $2 }
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
        let isAvailableUserWalletModelsContainsCustomerWalletId = _tangemPayOfferAvailabilityPublisher
            .map {
                $0.availableWalletSelection?
                    .wallets
                    .contains(
                        where: { $0.userWalletId.stringValue == customerWalletId }
                    ) ?? false
            }

        return Publishers
            .CombineLatest3(
                shouldShowGetTangemPay,
                shouldShowTangemPayBannerByAppSettings,
                isAvailableUserWalletModelsContainsCustomerWalletId
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

    private func isAvailableForTangemPayOffer(
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

                _ = await repo.isAvailableForTangemPayOffer(
                    userWalletModel: userWalletModel
                )
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
            .map { models -> TangemPayOfferAvailability in
                guard models.count > .zero else {
                    return .notAvailable
                }

                if models.count == 1, let only = models.first {
                    return .available(walletSelection: .single(only))
                }

                return .available(walletSelection: .multiple(models))
            }
            .sink(receiveValue: { [weak self] in
                self?._tangemPayOfferAvailabilitySubject.send($0)
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

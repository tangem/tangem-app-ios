//
//  CommonTangemPayAvailabilityRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay
import TangemVisa

final class CommonTangemPayAvailabilityRepository: TangemPayAvailabilityRepository {
    var tangemPayOfferAvailability: TangemPayOfferAvailability {
        tangemPayOfferAvailabilitySubject.value
    }

    var tangemPayDetailsEntrypointEligibleWalletSelectionPublisher: AnyPublisher<TangemPayWalletSelectionType?, Never> {
        tangemPayEligibleWalletSelectionPublisher(for: .details)
    }

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
    private let tangemPayOfferAvailabilitySubject = CurrentValueSubject<TangemPayOfferAvailability, Never>(.notAvailable)

    private var userWalletRepositoryEvents: some Publisher<UserWalletRepositoryEvent, Never> {
        userWalletRepository
            .eventProvider
            .removeDuplicates()
    }

    private var knownPaeraCustomersIds: some Publisher<[String], Never> {
        AppSettings.shared
            .$tangemPayIsPaeraCustomer
            .map {
                $0.filter { $0.value }.map(\.key)
            }
            .removeDuplicates()
    }

    private var currentWalletModelsContainPaeraCustomers: some Publisher<Bool, Never> {
        Publishers
            .CombineLatest(
                userWalletRepositoryEvents.mapToVoid().prepend(()),
                knownPaeraCustomersIds
            )
            .map(\.1)
            .withWeakCaptureOf(self)
            .map { repository, paeraIds in
                repository.userWalletRepository.models
                    .contains(where: { paeraIds.contains($0.userWalletId.stringValue) })
            }
            .removeDuplicates()
    }

    private var isTangemPayHiddenAnywhereOnce: some Publisher<Bool, Never> {
        AppSettings.shared
            .$tangemPayIsKYCHiddenForCustomerWalletId
            .removeDuplicates()
            .map { $0.contains(where: { $0.value }) }
    }

    private var shouldShowTangemPayBannerByAppSettings: some Publisher<Bool, Never> {
        Publishers
            .CombineLatest(
                AppSettings.shared.$tangemPayShouldShowGetBanner,
                isTangemPayHiddenAnywhereOnce.map { !$0 }
            )
            .map { $0 && $1 }
    }

    private let availabilityService = PaymentAccountAvailabilityServiceBuilder()
        .build()

    private var bag = Set<AnyCancellable>()

    init() {
        bind()

        runTask(in: self) { repo in
            await repo.requestEligibleDistributionChannels()
        }
    }

    func tangemPayBannerEntrypointEligibleWalletSelectionPublisher(
        for customerWalletId: String
    ) -> AnyPublisher<TangemPayWalletSelectionType?, Never> {
        Publishers.CombineLatest3(
            tangemPayEligibleWalletSelectionPublisher(for: .banner),
            shouldShowTangemPayBannerByAppSettings,
            currentWalletModelsContainPaeraCustomers
        )
        .map { walletSelection, shouldShowTangemPayBannerByAppSettings, currentWalletModelsContainPaeraCustomers in
            guard let walletSelection,
                  walletSelection.userWalletModelsIds.contains(customerWalletId),
                  shouldShowTangemPayBannerByAppSettings,
                  !currentWalletModelsContainPaeraCustomers
            else {
                return nil
            }

            return walletSelection
        }
        .eraseToAnyPublisher()
    }

    func userDidCloseGetTangemPayBanner() {
        AppSettings.shared.tangemPayShouldShowGetBanner = false
    }

    @discardableResult
    func requestEligibleDistributionChannels() async -> [TangemPayDistributionChannel] {
        do {
            let eligibleDistributionChannels =
                try await availabilityService
                    .loadEligibility()
                    .channels

            await MainActor.run {
                AppSettings.shared.tangemPayEligibleDistributionChannels = eligibleDistributionChannels.map(\.rawValue)
            }

            return eligibleDistributionChannels
        } catch {
            VisaLogger.error("Failed to receive TangemPay availability", error: error)
            return []
        }
    }

    private func tangemPayEligibleWalletSelectionPublisher(
        for distributionChannel: TangemPayDistributionChannel
    ) -> AnyPublisher<TangemPayWalletSelectionType?, Never> {
        let isDistributionChannelEligible = AppSettings.shared
            .$tangemPayEligibleDistributionChannels
            .map { $0.contains(distributionChannel.rawValue) }

        return Publishers
            .CombineLatest(
                isDistributionChannelEligible,
                tangemPayOfferAvailabilitySubject
            )
            .map { isDistributionChannelEligible, tangemPayOfferAvailability in
                guard let walletSelection = tangemPayOfferAvailability.availableWalletSelection,
                      isDistributionChannelEligible,
                      !RTCUtil().checkStatus().hasIssues
                else {
                    return nil
                }

                return walletSelection
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func requestIsAvailableForTangemPayOffer(
        userWalletModel: UserWalletModel
    ) {
        runTask(in: self) { repo in
            guard userWalletModel.supportsTangemPay else { return }
            let customerWalletId = userWalletModel.userWalletId.stringValue

            if await AppSettings.shared.tangemPayIsPaeraCustomer[
                customerWalletId,
                default: false
            ] {
                return
            }

            let result = try? await repo.availabilityService
                .getIsPaeraCustomer(
                    customerWalletId: customerWalletId
                )

            if result?.isTangemPayEnabled ?? false {
                await MainActor.run {
                    AppSettings.shared.tangemPayIsPaeraCustomer[
                        customerWalletId
                    ] = true
                }
            }
        }
    }

    private func bind() {
        let anyUserWalletConfigurationChangesPublisher =
            userWalletRepositoryEvents
                .withWeakCaptureOf(self)
                .flatMapLatest { repo, _ in
                    let publishers = repo.userWalletRepository.models
                        .map {
                            $0.updatePublisher
                                .filter { $0.isConfigurationChanged() }
                                .mapToVoid()
                        }

                    return Publishers
                        .MergeMany(publishers)
                }

        let anyUserWalletModelChangesPublisher =
            Publishers
                .Merge(
                    // Any UserWalletModel change is treated as a trigger.
                    // Covers repository-level changes
                    // and internal model updates.
                    //
                    // Examples:
                    // - User adds a new wallet.
                    // - User finishes HW wallet backup (seed + pass),
                    //   wallet becomes available, but no event is emitted
                    //   via `eventProvider`.
                    userWalletRepositoryEvents.mapToVoid(),
                    anyUserWalletConfigurationChangesPublisher
                )

        Publishers
            .CombineLatest(
                // Combine any UserWalletModel changes with known Paera customers.
                // Any change in either source triggers recalculation of
                // UserWalletModels availability for the TangemPay offer.
                anyUserWalletModelChangesPublisher.prepend(()),
                knownPaeraCustomersIds
            )
            .map(\.1)
            .withWeakCaptureOf(self)
            .map { repo, knownPaeraCustomersIds in
                return repo.userWalletRepository.models.filter {
                    $0.supportsTangemPay &&
                        !knownPaeraCustomersIds.contains($0.userWalletId.stringValue)
                }
                .asOfferAvailability()
            }
            .sink { [weak self] in
                self?.tangemPayOfferAvailabilitySubject.send($0)
            }
            .store(in: &bag)

        userWalletRepositoryEvents
            // On wallet selection or insertion,
            // request Paera customer status if it was not previously cached as TRUE.
            // This is a required behavior.
            .compactMap { $0.requestPaeraCustomerId }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { repo, id in
                guard let userWalletModel = repo.userWalletRepository.models.first(
                    where: { $0.userWalletId == id }
                ) else {
                    return
                }
                repo.requestIsAvailableForTangemPayOffer(
                    userWalletModel: userWalletModel
                )
            }
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

private extension Array where Element == UserWalletModel {
    func asOfferAvailability() -> TangemPayOfferAvailability {
        guard count > .zero else {
            return .notAvailable
        }
        let ids = map { $0.userWalletId.stringValue }

        if ids.count == 1, let only = ids.first {
            return .available(walletSelection: .single(only))
        }

        return .available(walletSelection: .multiple(ids))
    }
}

private extension UpdateResult {
    func isConfigurationChanged() -> Bool {
        if case .configurationChanged = self {
            return true
        }

        return false
    }
}

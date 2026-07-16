//
//  TangemPayOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay

enum TangemPayOnboardingSource {
    case deeplink(String)
    case other
}

final class TangemPayOnboardingViewModel: ObservableObject {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    let closeOfferScreen: @MainActor () -> Void
    @MainActor @Published private(set) var tangemPayOfferViewModel: TangemPayOfferViewModel?
    @MainActor @Published private(set) var showNewOnboarding = false

    private let source: TangemPayOnboardingSource
    private let availableSelection: TangemPayWalletSelectionType
    private let availabilityService: TangemPayAvailabilityService
    private weak var coordinator: TangemPayOnboardingRoutable?

    init(
        source: TangemPayOnboardingSource,
        availableSelection: TangemPayWalletSelectionType,
        availabilityService: TangemPayAvailabilityService = TangemPayAvailabilityServiceBuilder().build(),
        coordinator: TangemPayOnboardingRoutable?,
        closeOfferScreen: @escaping @MainActor () -> Void
    ) {
        self.source = source
        self.availableSelection = availableSelection
        self.availabilityService = availabilityService
        self.coordinator = coordinator
        self.closeOfferScreen = closeOfferScreen
    }

    @MainActor
    func onAppear() {
        switch source {
        case .other:
            makeOffer()

        case .deeplink(let deeplinkString):
            let minimumLoaderShowingTimeTask = Task {
                try await Task.sleep(nanoseconds: 800_000_000)
            }

            runTask { [self] in
                do {
                    try await validateDeeplink(deeplinkString: deeplinkString)
                    try? await minimumLoaderShowingTimeTask.value

                    makeOffer()
                } catch {
                    try? await minimumLoaderShowingTimeTask.value
                    closeOfferScreen()
                }
            }
        }
    }

    @MainActor
    func onOfferAppear() {
        let event: Analytics.Event = showNewOnboarding
            ? .visaOnboardingVisaNewOnboardingPageOpened
            : .visaOnboardingVisaActivationScreenOpened
        Analytics.log(event, analyticsSystems: .all)
    }

    @MainActor
    private func makeOffer() {
        showNewOnboarding = experimentService.variant(.tangemPayOnboardingVariant)?.value == OnboardingVariant.on.rawValue
        tangemPayOfferViewModel = TangemPayOfferViewModel(
            walletSelectionType: availableSelection,
            closeOfferScreen: closeOfferScreen,
            coordinator: coordinator
        )
    }

    private func validateDeeplink(deeplinkString: String) async throws {
        let validationResponse = try await availabilityService.validateDeeplink(deeplinkString: deeplinkString)
        switch validationResponse.status {
        case .valid:
            break
        case .invalid:
            throw TangemPayOnboardingError.invalidDeeplink
        }
    }
}

private extension TangemPayOnboardingViewModel {
    enum OnboardingVariant: String {
        case on = "newonboard_on"
        case off = "newonboard_off"
    }

    enum TangemPayOnboardingError: Error {
        case invalidDeeplink
        case offerIsNotAvailable
        case tangemPayIsNotAvailable
    }
}

extension TangemPayOnboardingViewModel: Identifiable {
    var id: String {
        "\(source)"
    }
}

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
    @Injected(\.tangemPayOnboardingAnalytics) private var analytics: TangemPayOnboardingAnalyticsService

    let closeOfferScreen: @MainActor () -> Void
    @MainActor @Published private(set) var tangemPayOfferViewModel: TangemPayOfferViewModel?
    @MainActor @Published private(set) var screenVersion: TangemPayOnboardingScreenVersion = .v1
    @MainActor @Published private(set) var regionUnavailable = false

    private let source: TangemPayOnboardingSource
    private let availableSelection: TangemPayWalletSelectionType
    private let availabilityService: TangemPayAvailabilityService
    private let screenVersionProvider: TangemPayOnboardingScreenVersionProvider
    private weak var coordinator: TangemPayOnboardingRoutable?

    init(
        source: TangemPayOnboardingSource,
        availableSelection: TangemPayWalletSelectionType,
        availabilityService: TangemPayAvailabilityService = TangemPayAvailabilityServiceBuilder().build(),
        screenVersionProvider: TangemPayOnboardingScreenVersionProvider = CommonTangemPayOnboardingScreenVersionProvider(),
        coordinator: TangemPayOnboardingRoutable?,
        closeOfferScreen: @escaping @MainActor () -> Void
    ) {
        self.source = source
        self.availableSelection = availableSelection
        self.availabilityService = availabilityService
        self.screenVersionProvider = screenVersionProvider
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
                } catch TangemPayOnboardingError.invalidDeeplink {
                    try? await minimumLoaderShowingTimeTask.value

                    if FeatureProvider.isAvailable(.tangemPayChooseCountry) {
                        closeOfferScreen()
                    } else {
                        showRegionUnavailable()
                    }
                } catch {
                    try? await minimumLoaderShowingTimeTask.value
                    closeOfferScreen()
                }
            }
        }
    }

    @MainActor
    func onOfferAppear() {
        switch screenVersion {
        case .v2:
            analytics.logNewOnboardingScreenOpened()
        case .v1:
            analytics.logOfferScreenOpened()
        }
    }

    @MainActor
    private func makeOffer() {
        screenVersion = screenVersionProvider.screenVersion()
        tangemPayOfferViewModel = TangemPayOfferViewModel(
            walletSelectionType: availableSelection,
            closeOfferScreen: closeOfferScreen,
            coordinator: coordinator
        )
    }

    @MainActor
    private func showRegionUnavailable() {
        regionUnavailable = true
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

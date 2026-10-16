//
//  TangemPayResidencyCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils
import TangemVisa

final class TangemPayResidencyCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published var path: [Route] = []
    @Published var isWaitlistPresented = false
    @Published var alert: AlertBinder?
    @Published var privacyPolicyViewModel: WebViewContainerViewModel?
    @Published private(set) var loadingItemId: String?
    @Published private(set) var navigationStackId = UUID()

    private(set) var product: TangemPayProduct = .paymentAccount
    private(set) var geoStore: TangemPayGeoStore?
    private(set) var unavailableRegion: TangemPayUnavailableRegion?
    private(set) var interactor: (any TangemPayResidencyInteractor)?

    private let availabilityService: TangemPayAvailabilityService
    private let analyticsLogger: TangemPayResidencyAnalyticsLogger

    private var selectedCountry: TangemPayGeoCountry?
    private var eligibilityTask: Task<Void, Never>?

    var loadingItemIdPublisher: AnyPublisher<String?, Never> {
        $loadingItemId.eraseToAnyPublisher()
    }

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        availabilityService = TangemPayAvailabilityServiceBuilder().build()
        analyticsLogger = CommonTangemPayResidencyAnalyticsLogger()
    }

    deinit {
        eligibilityTask?.cancel()
    }

    func start(with options: Options) {
        product = options.product
        geoStore = options.geoStore
        interactor = options.interactor
        analyticsLogger.logCountrySelectScreenOpened()
    }

    func close() {
        dismiss(with: .closed)
    }
}

// MARK: - Country and region

extension TangemPayResidencyCoordinator {
    func handle(_ output: CountrySelectionViewModel.Output) {
        switch output {
        case .selected(let country, let isHighlighted):
            analyticsLogger.logCountrySelected(country, isSuggested: isHighlighted)
            selectedCountry = country
            checkEligibility(country: country, region: nil)

        case .closed:
            close()
        }
    }

    func handle(_ output: RegionSelectionViewModel.Output) {
        switch output {
        case .selected(let region, let isHighlighted):
            guard let selectedCountry else {
                return
            }

            analyticsLogger.logStateSelected(region, isSuggested: isHighlighted)
            checkEligibility(country: selectedCountry, region: region)

        case .closed:
            close()
        }
    }
}

// MARK: - Unavailable region and waitlist

extension TangemPayResidencyCoordinator {
    func handle(_ output: TangemPayUnavailableRegionView.Output) {
        switch output {
        case .selectAnotherRegion:
            analyticsLogger.logSelectAnotherRegionTapped()
            selectedCountry = nil
            unavailableRegion = nil
            interactor?.beginResidency()
            path = []
            navigationStackId = UUID()
            analyticsLogger.logCountrySelectScreenOpened()

        case .joinWaitlist:
            analyticsLogger.logJoinWaitlistTapped()
            isWaitlistPresented = true
            analyticsLogger.logWaitlistScreenOpened()
        }
    }

    func handle(_ output: TangemPayWaitlistViewModel.Output) {
        switch output {
        case .joined:
            analyticsLogger.logWaitlistSaved()
            isWaitlistPresented = false
            dismiss(with: .joinedWaitlist)

        case .openPrivacyPolicy(let url):
            privacyPolicyViewModel = WebViewContainerViewModel(url: url, title: "", withCloseButton: true)

        case .close:
            closeWaitlist()
        }
    }

    func closeWaitlist() {
        isWaitlistPresented = false
    }
}

// MARK: - Eligibility

private extension TangemPayResidencyCoordinator {
    func checkEligibility(country: TangemPayGeoCountry, region: TangemPayGeoRegion?) {
        loadingItemId = region?.code ?? country.code

        eligibilityTask?.cancel()
        eligibilityTask = Task { @MainActor [weak self, availabilityService, product] in
            do {
                let response = try await availabilityService.checkEligibility(
                    product: product,
                    country: country.code,
                    region: region?.code
                )

                guard !Task.isCancelled, let self else { return }

                loadingItemId = nil
                handleEligibility(response, country: country, region: region)
            } catch {
                guard !Task.isCancelled, let self else { return }

                VisaLogger.error("Failed to check Tangem Pay eligibility", error: error)
                loadingItemId = nil
                showEligibilityError(country: country, region: region)
            }
        }
    }

    func handleEligibility(
        _ response: TangemPayEligibilityCheckResponse,
        country: TangemPayGeoCountry,
        region: TangemPayGeoRegion?
    ) {
        guard response.available else {
            analyticsLogger.logEligibilityCheckResult(isEligible: false, country: country, region: region)
            let unavailableRegion = TangemPayUnavailableRegion(
                country: response.countryCode,
                region: response.regionCode
            )
            self.unavailableRegion = unavailableRegion
            interactor?.completeResidency(.unavailable(unavailableRegion))
            path.append(.unavailableRegion)
            analyticsLogger.logRegionNotAvailableScreenOpened()
            return
        }

        if region == nil, country.hasRegions {
            path.append(.region(countryCode: country.code))
            analyticsLogger.logStateScreenOpened()
            return
        }

        analyticsLogger.logEligibilityCheckResult(isEligible: true, country: country, region: region)
        unavailableRegion = nil
        loadingItemId = region?.code ?? country.code
        interactor?.completeResidency(.eligible)
        dismiss(with: .available)
    }

    func showEligibilityError(country: TangemPayGeoCountry, region: TangemPayGeoRegion?) {
        alert = AlertBuilder.makeAlert(
            title: Localization.commonError,
            message: Localization.commonUnknownError,
            primaryButton: .default(Text(Localization.commonRetry)) { [weak self] in
                self?.checkEligibility(country: country, region: region)
            },
            secondaryButton: .cancel()
        )
    }
}

// MARK: - Options

extension TangemPayResidencyCoordinator {
    struct Options {
        let product: TangemPayProduct
        let geoStore: TangemPayGeoStore
        let interactor: any TangemPayResidencyInteractor
    }

    enum DismissOptions {
        case available
        case joinedWaitlist
        case closed
    }

    enum Route: Hashable {
        case region(countryCode: String)
        case unavailableRegion
    }
}

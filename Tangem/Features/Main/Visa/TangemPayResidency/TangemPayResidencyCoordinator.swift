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

    private(set) var product: TangemPayProduct = .paymentAccount
    private(set) var geoStore: TangemPayGeoStore?

    private let availabilityService: TangemPayAvailabilityService
    private let unavailableRegionStorage: TangemPayUnavailableRegionStorage

    private var selectedCountry: TangemPayGeoCountry?
    private var eligibilityTask: Task<Void, Never>?

    var loadingItemIdPublisher: AnyPublisher<String?, Never> {
        $loadingItemId.eraseToAnyPublisher()
    }

    var unavailableRegion: TangemPayUnavailableRegion? {
        unavailableRegionStorage.unavailableRegion(for: product)
    }

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        availabilityService = TangemPayAvailabilityServiceBuilder().build()
        unavailableRegionStorage = AppSettings.shared
    }

    deinit {
        eligibilityTask?.cancel()
    }

    func start(with options: Options) {
        product = options.product
        geoStore = options.geoStore
    }

    func close() {
        dismiss(with: .closed)
    }
}

// MARK: - Country and region

extension TangemPayResidencyCoordinator {
    func handle(_ output: CountrySelectionViewModel.Output) {
        switch output {
        case .selected(let country):
            selectedCountry = country
            checkEligibility(country: country, region: nil)

        case .closed:
            close()
        }
    }

    func handle(_ output: RegionSelectionViewModel.Output) {
        switch output {
        case .selected(let region):
            guard let selectedCountry else {
                return
            }

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
            selectedCountry = nil
            path = []

        case .joinWaitlist:
            isWaitlistPresented = true
        }
    }

    func handle(_ output: TangemPayWaitlistViewModel.Output) {
        switch output {
        case .joined:
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
            unavailableRegionStorage.setUnavailableRegion(
                TangemPayUnavailableRegion(country: response.country, region: response.region),
                for: product
            )
            path.append(.unavailableRegion)
            return
        }

        if region == nil, country.hasRegions {
            path.append(.region(countryCode: country.code))
            return
        }

        unavailableRegionStorage.clearUnavailableRegion(for: product)
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

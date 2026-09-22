//
//  TangemPayWaitlistViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils
import TangemVisa

@MainActor
final class TangemPayWaitlistViewModel: ObservableObject {
    @Published var field = TangemPayFormField(
        id: .email,
        title: Localization.tangempayOrderDataEmail,
        placeholder: Localization.tangempayWaitlistEmailPlaceholder
    )
    @Published var alert: AlertBinder?
    @Published private(set) var isMarketingConsentOn = false
    @Published private(set) var isSaving = false

    private let product: TangemPayWaitlistProduct
    private let country: String
    private let region: String?
    private let service: TangemPayWaitlistService
    private let idempotencyKey = TangemPayIdempotencyKey.make(UUID().uuidString)
    private let output: (Output) -> Void

    private var focusedFieldID: TangemPayFormField.ID?

    init(
        product: TangemPayWaitlistProduct,
        country: String,
        region: String?,
        service: TangemPayWaitlistService,
        output: @escaping (Output) -> Void
    ) {
        self.product = product
        self.country = country
        self.region = region
        self.service = service
        self.output = output
    }

    var contentState: TangemPayWaitlistContentView.State {
        TangemPayWaitlistContentView.State(
            isMarketingConsentOn: isMarketingConsentOn,
            isSaveEnabled: field.currentError == nil,
            isSaving: isSaving
        )
    }

    func handle(_ action: TangemPayWaitlistContentView.Action) {
        switch action {
        case .emailChanged:
            guard field.error != nil else { return }

            field.error = nil

        case .marketingConsentTap:
            isMarketingConsentOn.toggle()

        case .privacyPolicyTap(let url):
            output(.openPrivacyPolicy(url))

        case .saveTap:
            submit()
        }
    }

    func focusedFieldDidChange(to id: TangemPayFormField.ID?) {
        if let blurredFieldID = focusedFieldID, blurredFieldID != id {
            field.error = field.currentError
        }

        focusedFieldID = id
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Save

private extension TangemPayWaitlistViewModel {
    func submit() {
        field.error = field.currentError

        guard field.error == nil, !isSaving else {
            return
        }

        isSaving = true

        Task { [weak self] in
            guard let self else {
                return
            }

            do throws(TangemPayWaitlistError) {
                _ = try await service.joinWaitlist(makeRequest(), idempotencyKey: idempotencyKey)
                handleJoined()
            } catch {
                handleFailure(error)
            }
        }
    }

    func makeRequest() -> TangemPayJoinWaitlistRequest {
        TangemPayJoinWaitlistRequest(
            email: field.text.trimmed(),
            product: product,
            country: country,
            region: region,
            marketingConsent: isMarketingConsentOn
        )
    }

    func handleJoined() {
        isSaving = false
        output(.joined)
    }

    func handleFailure(_ error: TangemPayWaitlistError) {
        isSaving = false

        switch error {
        case .invalidEmail:
            field.error = .invalidEmail

        case .failed(let apiError):
            VisaLogger.error("Failed to join Tangem Pay waitlist", error: apiError)
            alert = AlertBinder(title: Localization.commonError, message: Localization.commonUnknownError)
        }
    }
}

// MARK: - Output

extension TangemPayWaitlistViewModel {
    enum Output {
        case joined
        case openPrivacyPolicy(URL)
        case close
    }
}

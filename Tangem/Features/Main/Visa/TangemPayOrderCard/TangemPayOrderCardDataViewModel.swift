//
//  TangemPayOrderCardDataViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils

final class TangemPayOrderCardDataViewModel: ObservableObject, Identifiable {
    @Published var sections: [TangemPayOrderCardDataSection]
    @Published private(set) var isPlacingOrder = false
    @Published var alert: AlertBinder?

    private let purpose: TangemPayOrderCardPurpose
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayOrderCardDataRoutable?
    private var focusedFieldID: TangemPayOrderCardDataField.ID?
    private var orderTask: Task<Void, Never>?

    init(
        purpose: TangemPayOrderCardPurpose,
        nameOnCard: String?,
        countryName: String?,
        email: String?,
        phoneMask: String?,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayOrderCardDataRoutable?
    ) {
        sections = Self.makeSections(
            nameOnCard: nameOnCard,
            countryName: countryName,
            email: email,
            phoneMask: phoneMask
        )
        self.purpose = purpose
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        Analytics.log(.visaPlasticAddressScreenOpened)
    }

    var title: String {
        switch purpose {
        case .issue:
            Localization.tangempayOrderTypeTitle
        case .reissue:
            Localization.tangempayCardDetailsReissueCard
        }
    }

    var isOrderEnabled: Bool {
        sections.flatMap(\.fields).allSatisfy { $0.currentError == nil }
    }

    func focusedFieldDidChange(to id: TangemPayOrderCardDataField.ID?) {
        defer { focusedFieldID = id }

        guard let blurredFieldID = focusedFieldID, blurredFieldID != id else { return }

        updateField(blurredFieldID) { $0.error = $0.currentError }
    }

    func fieldDidChange(_ id: TangemPayOrderCardDataField.ID) {
        guard focusedFieldID == id, field(id)?.error != nil else { return }

        updateField(id) { $0.error = nil }
    }

    func placeOrder() {
        guard !isPlacingOrder, isOrderEnabled else { return }

        Analytics.log(.visaPlasticOrderCardClicked)
        isPlacingOrder = true

        orderTask = runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.submitOrder()
            } catch {
                guard !Task.isCancelled else { return }

                viewModel.isPlacingOrder = false
                viewModel.handle(OrderFailure(error))
                return
            }

            guard !Task.isCancelled else { return }

            viewModel.isPlacingOrder = false
            viewModel.coordinator?.orderCardDataDidPlaceOrder()
        }
    }

    func fieldAfter(_ id: TangemPayOrderCardDataField.ID) -> TangemPayOrderCardDataField.ID? {
        let editable = sections.flatMap(\.fields).filter(\.isEditable).map(\.id)

        guard let index = editable.firstIndex(of: id), editable.indices.contains(index + 1) else {
            return nil
        }

        return editable[index + 1]
    }

    var lastFieldID: TangemPayOrderCardDataField.ID? {
        sections.last?.fields.last?.id
    }

    var lastFieldHasError: Bool {
        sections.last?.fields.last?.error != nil
    }

    func isLastField(_ id: TangemPayOrderCardDataField.ID) -> Bool {
        lastFieldID == id
    }

    func back() {
        orderTask?.cancel()
        coordinator?.orderCardDataDidGoBack()
    }

    func close() {
        orderTask?.cancel()
        coordinator?.closeOrderCardData()
    }
}

// MARK: - Order submission

private extension TangemPayOrderCardDataViewModel {
    func submitOrder() async throws {
        switch purpose {
        case .issue:
            try await tangemPayAccount.orderPlasticCard(
                embossName: text(for: .nameOnCard),
                shippingAddress: shippingAddress
            )
        case .reissue(let sourceProductInstanceId):
            try await tangemPayAccount.reissuePlasticCard(
                sourceProductInstanceId: sourceProductInstanceId,
                embossName: text(for: .nameOnCard),
                shippingAddress: shippingAddress
            )
        }
    }
}

// MARK: - Errors

private extension TangemPayOrderCardDataViewModel {
    enum OrderFailure {
        case insufficientBalance
        case activeOrderExists
        case offerUnavailable
        case invalidSourceCard
        case invalidShippingAddress
        case invalidEmbossName
        case unspecified

        init(_ error: any Error) {
            if case TangemPayOrderResolverError.insufficientBalance = error {
                self = .insufficientBalance
                return
            }

            if case TangemPayAccountError.missingCardIssueOffer = error {
                self = .offerUnavailable
                return
            }

            self = switch (error as? TangemPayAPIServiceError)?.apiErrorCode {
            case TangemPayAPIError.Code.cardIssueActiveOrderExists,
                 TangemPayAPIError.Code.cardReissuePlasticActiveOrderExists: .activeOrderExists
            case TangemPayAPIError.Code.cardIssueOfferNotAvailable,
                 TangemPayAPIError.Code.cardReissuePlasticNotAvailable: .offerUnavailable
            case TangemPayAPIError.Code.cardReissuePlasticInsufficientBalance: .insufficientBalance
            case TangemPayAPIError.Code.cardReissuePlasticInvalidSourceCard: .invalidSourceCard
            case TangemPayAPIError.Code.cardIssueInvalidShippingAddress,
                 TangemPayAPIError.Code.cardReissuePlasticInvalidShippingAddress: .invalidShippingAddress
            case TangemPayAPIError.Code.cardIssueInvalidEmbossName,
                 TangemPayAPIError.Code.cardReissuePlasticInvalidEmbossName: .invalidEmbossName
            default: .unspecified
            }
        }

        var message: String {
            switch self {
            case .insufficientBalance: Localization.tangempayOrderCardErrorInsufficientBalance
            case .activeOrderExists: Localization.tangempayOrderCardErrorActiveOrder
            case .offerUnavailable: Localization.tangempayOrderCardErrorOfferUnavailable
            case .invalidSourceCard: Localization.tangempayOrderCardErrorInvalidSourceCard
            case .invalidShippingAddress: Localization.tangempayOrderCardErrorInvalidAddress
            case .invalidEmbossName: Localization.tangempayOrderCardErrorInvalidEmbossName
            case .unspecified: Localization.commonSomethingWentWrong
            }
        }

        var closesFlow: Bool {
            switch self {
            case .insufficientBalance, .activeOrderExists, .offerUnavailable, .invalidSourceCard: true
            case .invalidShippingAddress, .invalidEmbossName, .unspecified: false
            }
        }
    }

    func resyncActiveOrder() {
        switch purpose {
        case .issue:
            runTask { [tangemPayAccount] in await tangemPayAccount.resumeActiveIssueOrderPolling() }
        case .reissue:
            runTask { [tangemPayAccount] in await tangemPayAccount.loadCustomerInfo() }
        }
    }

    func handle(_ failure: OrderFailure) {
        switch failure {
        case .activeOrderExists:
            resyncActiveOrder()
        case .offerUnavailable:
            runTask { [tangemPayAccount] in await tangemPayAccount.loadOffers() }
        case .insufficientBalance, .invalidSourceCard, .invalidShippingAddress, .invalidEmbossName, .unspecified:
            break
        }

        guard case .unspecified = failure else {
            alert = AlertBinder(alert: Alert(
                title: Text(failure.message),
                dismissButton: .default(Text(Localization.commonOk)) { [weak self] in
                    guard failure.closesFlow else { return }

                    self?.close()
                }
            ))
            return
        }

        coordinator?.orderCardDataDidFailUnexpectedly(retry: { [weak self] in
            self?.placeOrder()
        })
    }
}

// MARK: - Fields

private extension TangemPayOrderCardDataViewModel {
    func field(_ id: TangemPayOrderCardDataField.ID) -> TangemPayOrderCardDataField? {
        sections.flatMap(\.fields).first { $0.id == id }
    }

    func updateField(_ id: TangemPayOrderCardDataField.ID, transform: (inout TangemPayOrderCardDataField) -> Void) {
        for sectionIndex in sections.indices {
            guard let fieldIndex = sections[sectionIndex].fields.firstIndex(where: { $0.id == id }) else { continue }

            transform(&sections[sectionIndex].fields[fieldIndex])
            return
        }
    }

    func text(for id: TangemPayOrderCardDataField.ID) -> String {
        field(id)?.text.trimmed() ?? ""
    }

    var phoneNumber: String {
        guard let phone = field(.phone) else { return "" }

        return phone.inputMask?.e164(from: phone.text) ?? ("+" + phone.text.filter(\.isWholeNumber))
    }

    var shippingAddress: TangemPayPlaceOrderRequest.ShippingAddress {
        TangemPayPlaceOrderRequest.ShippingAddress(
            firstName: text(for: .firstName),
            lastName: text(for: .lastName),
            line1: text(for: .addressLine1),
            line2: text(for: .addressLine2).nilIfEmpty,
            city: text(for: .city),
            region: text(for: .region),
            postalCode: text(for: .postalCode),
            phoneNumber: phoneNumber
        )
    }

    static func makeSections(
        nameOnCard: String?,
        countryName: String?,
        email: String?,
        phoneMask: String?
    ) -> [TangemPayOrderCardDataSection] {
        [
            TangemPayOrderCardDataSection(
                id: .cardName,
                fields: [
                    TangemPayOrderCardDataField(
                        id: .nameOnCard,
                        title: Localization.tangempayOrderDataNameOnCard,
                        text: nameOnCard ?? ""
                    ),
                ]
            ),
            TangemPayOrderCardDataSection(
                id: .recipient,
                fields: recipientFields(countryName: countryName, email: email, phoneMask: phoneMask)
            ),
        ]
    }

    static func recipientFields(
        countryName: String?,
        email: String?,
        phoneMask: String?
    ) -> [TangemPayOrderCardDataField] {
        [
            TangemPayOrderCardDataField(
                id: .country,
                title: Localization.tangempayOrderDataCountry,
                text: countryName ?? "",
                isEditable: false
            ),
            TangemPayOrderCardDataField(
                id: .email,
                title: Localization.tangempayOrderDataEmail,
                text: email ?? "",
                isEditable: false
            ),
            TangemPayOrderCardDataField(
                id: .firstName,
                title: Localization.tangempayOrderDataFirstName,
                textContentType: .givenName
            ),
            TangemPayOrderCardDataField(
                id: .lastName,
                title: Localization.tangempayOrderDataLastName,
                textContentType: .familyName
            ),
            TangemPayOrderCardDataField(
                id: .region,
                title: Localization.tangempayOrderDataRegion,
                textContentType: .addressState
            ),
            TangemPayOrderCardDataField(
                id: .city,
                title: Localization.tangempayOrderDataCity,
                textContentType: .addressCity
            ),
            TangemPayOrderCardDataField(
                id: .addressLine1,
                title: Localization.tangempayOrderDataAddressLine1,
                textContentType: .streetAddressLine1
            ),
            TangemPayOrderCardDataField(
                id: .addressLine2,
                title: Localization.tangempayOrderDataAddressLine2,
                isOptional: true,
                textContentType: .streetAddressLine2
            ),
            TangemPayOrderCardDataField(
                id: .postalCode,
                title: Localization.tangempayOrderDataPostalCode,
                textContentType: .postalCode
            ),
            TangemPayOrderCardDataField(
                id: .phone,
                title: Localization.tangempayOrderDataPhone,
                keyboardType: .phonePad,
                textContentType: .telephoneNumber,
                mask: phoneMask
            ),
        ]
    }
}

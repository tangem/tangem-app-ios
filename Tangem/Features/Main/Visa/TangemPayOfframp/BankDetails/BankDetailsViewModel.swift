//
//  BankDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemPay

@MainActor
final class BankDetailsViewModel: ObservableObject {
    @Published var fields: [TangemPayFormField] = []
    @Published private(set) var focusedFieldID: TangemPayFormField.ID?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (Output) -> Void

    private var region: TangemPayGeoRegion?
    private var loggedFilledFields: Set<TangemPayFormField.ID> = []

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        title: String,
        stepSubtitle: String?,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.analyticsLogger = analyticsLogger
        self.output = output

        refresh()

        analyticsLogger.logRecipientBankDetailsScreenOpened()
    }

    var contentState: OfframpFormContentView.StateModel {
        OfframpFormContentView.StateModel(
            isContinueEnabled: isContinueEnabled,
            hasFieldBefore: fieldBefore(focusedFieldID) != nil,
            hasFieldAfter: fieldAfter(focusedFieldID) != nil
        )
    }

    var isContinueEnabled: Bool {
        fields.allSatisfy { $0.currentError == nil }
    }

    func refresh() {
        let details = orderBuilder.bankDetails
        region = details?.region
        fields = makeFields(details: details)
    }

    func focusedFieldDidChange(to id: TangemPayFormField.ID?) {
        defer { focusedFieldID = id }

        guard let blurredFieldID = focusedFieldID, blurredFieldID != id else { return }

        updateField(blurredFieldID) { $0.error = $0.currentError }
        logFieldFilledIfNeeded(blurredFieldID)
    }

    func fieldDidChange(_ id: TangemPayFormField.ID) {
        guard field(id)?.error != nil else { return }

        updateField(id) { $0.error = nil }
    }

    func fieldBefore(_ id: TangemPayFormField.ID?) -> TangemPayFormField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return fields[..<index].last { !$0.isSelectable }?.id
    }

    func fieldAfter(_ id: TangemPayFormField.ID?) -> TangemPayFormField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return fields[(index + 1)...].first { !$0.isSelectable }?.id
    }

    func submit() {
        guard isContinueEnabled, let region else { return }

        orderBuilder.set(bankDetails: makeBankDetails(region: region))

        focusedFieldID.map(logFieldFilledIfNeeded)
        analyticsLogger.logRecipientBankDetailsContinueClicked()
        output(.continueWizard)
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Field analytics

private extension BankDetailsViewModel {
    func logFieldFilledIfNeeded(_ id: TangemPayFormField.ID) {
        guard !text(for: id).isEmpty, loggedFilledFields.insert(id).inserted else { return }

        analyticsLogger.logRecipientBankDetailsFieldFilled(field: id)
    }
}

// MARK: - Fields

private extension BankDetailsViewModel {
    func field(_ id: TangemPayFormField.ID) -> TangemPayFormField? {
        fields.first { $0.id == id }
    }

    func updateField(_ id: TangemPayFormField.ID, transform: (inout TangemPayFormField) -> Void) {
        guard let index = fields.firstIndex(where: { $0.id == id }) else { return }

        transform(&fields[index])
    }

    func text(for id: TangemPayFormField.ID) -> String {
        field(id)?.text.trimmed() ?? ""
    }

    func makeBankDetails(region: TangemPayGeoRegion) -> TangemPayOfframpBankDetails {
        TangemPayOfframpBankDetails(
            name: text(for: .bankName),
            line1: text(for: .bankLine1),
            city: text(for: .bankCity),
            region: region,
            postalCode: text(for: .bankPostalCode)
        )
    }

    func makeFields(details: TangemPayOfframpBankDetails?) -> [TangemPayFormField] {
        let values = details.map(Self.restoredValues(from:)) ?? [:]

        return [
            TangemPayFormField(
                id: .bankName,
                title: Localization.tangempayWithdrawBankFieldBankName,
                placeholder: Localization.tangempayWithdrawBankPlaceholderBankName
            ),
            TangemPayFormField(
                id: .bankRegion,
                title: Localization.tangempayWithdrawBankFieldBankRegion,
                placeholder: Localization.tangempayWithdrawBankPlaceholderNotSelected,
                onSelect: { [weak self] in self?.selectRegion() }
            ),
            TangemPayFormField(
                id: .bankCity,
                title: Localization.tangempayWithdrawBankFieldBankCity,
                placeholder: Localization.tangempayWithdrawBankPlaceholderCity
            ),
            TangemPayFormField(
                id: .bankLine1,
                title: Localization.tangempayWithdrawBankFieldBankAddressLine1,
                placeholder: Localization.tangempayWithdrawBankPlaceholderAddressLine1
            ),
            TangemPayFormField(
                id: .bankPostalCode,
                title: Localization.tangempayOrderDataPostalCode,
                placeholder: "0000",
                countryCode: TangemPayOfframpOrderBuilder.bankCountryCode
            ),
        ]
        .map { field in
            var field = field
            field.text = values[field.id] ?? ""
            return field
        }
    }

    static func restoredValues(
        from details: TangemPayOfframpBankDetails
    ) -> [TangemPayFormField.ID: String] {
        [
            .bankName: details.name,
            .bankRegion: details.region.name,
            .bankCity: details.city,
            .bankLine1: details.line1,
            .bankPostalCode: details.postalCode,
        ]
    }
}

// MARK: - Geo selection

private extension BankDetailsViewModel {
    func selectRegion() {
        output(
            .selectRegion(
                countryCode: TangemPayOfframpOrderBuilder.bankCountryCode,
                selectedCode: region?.code
            ) { [weak self] selected in
                self?.region = selected

                self?.updateField(.bankRegion) {
                    $0.text = selected.name
                    $0.error = nil
                }

                self?.logFieldFilledIfNeeded(.bankRegion)
            }
        )
    }
}

// MARK: - Output

extension BankDetailsViewModel {
    enum Output {
        case selectRegion(countryCode: String, selectedCode: String?, (TangemPayGeoRegion) -> Void)
        case continueWizard
        case close
    }
}

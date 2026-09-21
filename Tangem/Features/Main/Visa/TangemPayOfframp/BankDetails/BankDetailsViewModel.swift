//
//  BankDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay

@MainActor
final class BankDetailsViewModel: ObservableObject {
    @Published var fields: [OfframpFormField] = []
    @Published private(set) var focusedFieldID: OfframpFormField.ID?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let output: (Output) -> Void

    private var region: TangemPayGeoRegion?

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        title: String,
        stepSubtitle: String?,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.output = output

        refresh()
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

    func focusedFieldDidChange(to id: OfframpFormField.ID?) {
        defer { focusedFieldID = id }

        guard let blurredFieldID = focusedFieldID, blurredFieldID != id else { return }

        updateField(blurredFieldID) { $0.error = $0.currentError }
    }

    func fieldDidChange(_ id: OfframpFormField.ID) {
        guard field(id)?.error != nil else { return }

        updateField(id) { $0.error = nil }
    }

    func fieldBefore(_ id: OfframpFormField.ID?) -> OfframpFormField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return fields[..<index].last { !$0.isSelectable }?.id
    }

    func fieldAfter(_ id: OfframpFormField.ID?) -> OfframpFormField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return fields[(index + 1)...].first { !$0.isSelectable }?.id
    }

    func submit() {
        guard isContinueEnabled, let region else { return }

        orderBuilder.set(bankDetails: makeBankDetails(region: region))
        output(.continueWizard)
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Fields

private extension BankDetailsViewModel {
    func field(_ id: OfframpFormField.ID) -> OfframpFormField? {
        fields.first { $0.id == id }
    }

    func updateField(_ id: OfframpFormField.ID, transform: (inout OfframpFormField) -> Void) {
        guard let index = fields.firstIndex(where: { $0.id == id }) else { return }

        transform(&fields[index])
    }

    func text(for id: OfframpFormField.ID) -> String {
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

    // [REDACTED_TODO_COMMENT]
    func makeFields(details: TangemPayOfframpBankDetails?) -> [OfframpFormField] {
        let values = details.map(Self.restoredValues(from:)) ?? [:]

        return [
            OfframpFormField(
                id: .bankName,
                title: "Bank name",
                placeholder: "Eg., Goldman Sachs"
            ),
            OfframpFormField(
                id: .bankRegion,
                title: "Bank region / state",
                placeholder: "Not selected",
                onSelect: { [weak self] in self?.selectRegion() }
            ),
            OfframpFormField(
                id: .bankCity,
                title: "Bank city",
                placeholder: "Eg., Night City"
            ),
            OfframpFormField(
                id: .bankLine1,
                title: "Bank address line 1",
                placeholder: "Eg., Ebunike st., Apt. 32"
            ),
            OfframpFormField(
                id: .bankPostalCode,
                title: "Postal code",
                placeholder: "0000"
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
    ) -> [OfframpFormField.ID: String] {
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

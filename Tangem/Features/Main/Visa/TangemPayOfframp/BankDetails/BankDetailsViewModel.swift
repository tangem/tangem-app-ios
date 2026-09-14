//
//  BankDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

@MainActor
final class BankDetailsViewModel: ObservableObject {
    @Published var fields: [OfframpFormField]
    @Published private(set) var focusedFieldID: OfframpFormField.ID?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let output: (Output) -> Void

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

        fields = Self.makeFields(details: orderBuilder.bankDetails)
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
        fields = Self.makeFields(details: orderBuilder.bankDetails)
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
        guard let id, let index = fields.firstIndex(where: { $0.id == id }), index > 0 else {
            return nil
        }

        return fields[index - 1].id
    }

    func fieldAfter(_ id: OfframpFormField.ID?) -> OfframpFormField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }), fields.indices.contains(index + 1) else {
            return nil
        }

        return fields[index + 1].id
    }

    func submit() {
        guard isContinueEnabled else { return }

        orderBuilder.set(bankDetails: makeBankDetails())
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

    func makeBankDetails() -> TangemPayOfframpBankDetails {
        TangemPayOfframpBankDetails(
            name: text(for: .bankName),
            line1: text(for: .bankLine1),
            city: text(for: .bankCity),
            region: text(for: .bankRegion).uppercased(),
            postalCode: text(for: .bankPostalCode)
        )
    }

    // [REDACTED_TODO_COMMENT]
    static func makeFields(details: TangemPayOfframpBankDetails?) -> [OfframpFormField] {
        let fields = [
            OfframpFormField(
                id: .bankName,
                title: "Bank name",
                placeholder: "Eg., Goldman Sachs"
            ),
            OfframpFormField(
                id: .bankRegion,
                title: "Bank region / state",
                placeholder: "Not selected"
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

        guard let details else {
            return fields
        }

        let values = restoredValues(from: details)

        return fields.map { field in
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
            .bankRegion: details.region,
            .bankCity: details.city,
            .bankLine1: details.line1,
            .bankPostalCode: details.postalCode,
        ]
    }
}

// MARK: - Output

extension BankDetailsViewModel {
    enum Output {
        case continueWizard
        case close
    }
}

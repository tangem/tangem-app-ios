//
//  PersonalDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

@MainActor
final class PersonalDetailsViewModel: ObservableObject {
    @Published var fields: [PersonalDetailsField]
    @Published private(set) var focusedFieldID: PersonalDetailsField.ID?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let isBusiness: Bool
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

        isBusiness = orderBuilder.recipient == .newBusiness
        fields = Self.makeFields(isBusiness: isBusiness, details: orderBuilder.personalDetails)
    }

    var contentState: PersonalDetailsContentView.StateModel {
        PersonalDetailsContentView.StateModel(
            isContinueEnabled: isContinueEnabled,
            hasFieldBefore: fieldBefore(focusedFieldID) != nil,
            hasFieldAfter: fieldAfter(focusedFieldID) != nil
        )
    }

    var isContinueEnabled: Bool {
        fields.allSatisfy { $0.currentError == nil }
    }

    func focusedFieldDidChange(to id: PersonalDetailsField.ID?) {
        defer { focusedFieldID = id }

        guard let blurredFieldID = focusedFieldID, blurredFieldID != id else { return }

        updateField(blurredFieldID) { $0.error = $0.currentError }
    }

    func fieldDidChange(_ id: PersonalDetailsField.ID) {
        guard field(id)?.error != nil else { return }

        updateField(id) { $0.error = nil }
    }

    func fieldBefore(_ id: PersonalDetailsField.ID?) -> PersonalDetailsField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }), index > 0 else {
            return nil
        }

        return fields[index - 1].id
    }

    func fieldAfter(_ id: PersonalDetailsField.ID?) -> PersonalDetailsField.ID? {
        guard let id, let index = fields.firstIndex(where: { $0.id == id }), fields.indices.contains(index + 1) else {
            return nil
        }

        return fields[index + 1].id
    }

    func submit() {
        guard isContinueEnabled else { return }

        orderBuilder.set(personalDetails: makePersonalDetails())
        output(.continueWizard)
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Fields

private extension PersonalDetailsViewModel {
    func field(_ id: PersonalDetailsField.ID) -> PersonalDetailsField? {
        fields.first { $0.id == id }
    }

    func updateField(_ id: PersonalDetailsField.ID, transform: (inout PersonalDetailsField) -> Void) {
        guard let index = fields.firstIndex(where: { $0.id == id }) else { return }

        transform(&fields[index])
    }

    func text(for id: PersonalDetailsField.ID) -> String {
        field(id)?.text.trimmed() ?? ""
    }

    func makePersonalDetails() -> TangemPayOfframpPersonalDetails {
        TangemPayOfframpPersonalDetails(
            name: makeName(),
            accountNumber: text(for: .accountNumber),
            routingNumber: text(for: .routingNumber),
            line1: text(for: .line1),
            line2: text(for: .line2).nilIfEmpty,
            city: text(for: .city),
            region: text(for: .region).uppercased(),
            postalCode: text(for: .postalCode),
            countryCode: text(for: .countryCode).uppercased()
        )
    }

    func makeName() -> TangemPayOfframpPersonalDetails.Name {
        guard !isBusiness else {
            return .business(name: text(for: .businessName))
        }

        return .individual(firstName: text(for: .firstName), lastName: text(for: .lastName))
    }

    static func makeFields(
        isBusiness: Bool,
        details: TangemPayOfframpPersonalDetails?
    ) -> [PersonalDetailsField] {
        let fields = accountFields() + nameFields(isBusiness: isBusiness) + addressFields()

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

    // [REDACTED_TODO_COMMENT]
    static func accountFields() -> [PersonalDetailsField] {
        [
            PersonalDetailsField(
                id: .accountNumber,
                title: "Account number",
                placeholder: "000000000000"
            ),
            PersonalDetailsField(
                id: .routingNumber,
                title: "Routing number",
                placeholder: "000000000000"
            ),
        ]
    }

    // [REDACTED_TODO_COMMENT]
    static func nameFields(isBusiness: Bool) -> [PersonalDetailsField] {
        if isBusiness {
            return [
                PersonalDetailsField(
                    id: .businessName,
                    title: "Business name",
                    placeholder: "Eg., Dunder Mifflin LLC"
                ),
            ]
        }

        return [
            PersonalDetailsField(
                id: .firstName,
                title: "First name",
                placeholder: "John"
            ),
            PersonalDetailsField(
                id: .lastName,
                title: "Last name",
                placeholder: "Doe"
            ),
        ]
    }

    // [REDACTED_TODO_COMMENT]
    static func addressFields() -> [PersonalDetailsField] {
        [
            PersonalDetailsField(
                id: .countryCode,
                title: "Country",
                placeholder: "Not selected"
            ),
            PersonalDetailsField(
                id: .region,
                title: "Region / state",
                placeholder: "Not selected"
            ),
            PersonalDetailsField(
                id: .city,
                title: "City",
                placeholder: "Eg., Night City"
            ),
            PersonalDetailsField(
                id: .line1,
                title: "Address line 1",
                placeholder: "Eg., Ebunike st., Apt. 32"
            ),
            PersonalDetailsField(
                id: .line2,
                title: "Address line 2",
                placeholder: "Eg., Ebunike st., Apt. 32"
            ),
            PersonalDetailsField(
                id: .postalCode,
                title: "Postal code",
                placeholder: "0000"
            ),
        ]
    }

    static func restoredValues(
        from details: TangemPayOfframpPersonalDetails
    ) -> [PersonalDetailsField.ID: String] {
        var values: [PersonalDetailsField.ID: String] = [
            .accountNumber: details.accountNumber,
            .routingNumber: details.routingNumber,
            .countryCode: details.countryCode,
            .region: details.region,
            .city: details.city,
            .line1: details.line1,
            .line2: details.line2 ?? "",
            .postalCode: details.postalCode,
        ]

        switch details.name {
        case .individual(let firstName, let lastName):
            values[.firstName] = firstName
            values[.lastName] = lastName

        case .business(let name):
            values[.businessName] = name
        }

        return values
    }
}

// MARK: - Output

extension PersonalDetailsViewModel {
    enum Output {
        case continueWizard
        case close
    }
}

//
//  PersonalDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay

@MainActor
final class PersonalDetailsViewModel: ObservableObject {
    @Published var fields: [OfframpFormField] = []
    @Published private(set) var focusedFieldID: OfframpFormField.ID?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let isBusiness: Bool
    private let output: (Output) -> Void

    private var country: TangemPayGeoCountry?
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

        isBusiness = orderBuilder.recipient == .newBusiness

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
        let details = orderBuilder.personalDetails
        country = details?.country
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
        guard isContinueEnabled, let country else { return }

        orderBuilder.set(personalDetails: makePersonalDetails(country: country))
        output(.continueWizard)
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Fields

private extension PersonalDetailsViewModel {
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

    func makePersonalDetails(country: TangemPayGeoCountry) -> TangemPayOfframpPersonalDetails {
        TangemPayOfframpPersonalDetails(
            name: makeName(),
            accountNumber: text(for: .accountNumber),
            routingNumber: text(for: .routingNumber),
            line1: text(for: .line1),
            line2: text(for: .line2).nilIfEmpty,
            city: text(for: .city),
            country: country,
            region: region,
            regionText: text(for: .region),
            postalCode: text(for: .postalCode)
        )
    }

    func makeName() -> TangemPayOfframpPersonalDetails.Name {
        guard !isBusiness else {
            return .business(name: text(for: .businessName))
        }

        return .individual(firstName: text(for: .firstName), lastName: text(for: .lastName))
    }

    func makeFields(details: TangemPayOfframpPersonalDetails?) -> [OfframpFormField] {
        let values = details.map(Self.restoredValues(from:)) ?? [:]

        return (Self.accountFields() + Self.nameFields(isBusiness: isBusiness) + addressFields())
            .map { field in
                var field = field
                field.text = values[field.id] ?? ""
                return field
            }
    }

    // [REDACTED_TODO_COMMENT]
    static func accountFields() -> [OfframpFormField] {
        [
            OfframpFormField(
                id: .accountNumber,
                title: "Account number",
                placeholder: "000000000000"
            ),
            OfframpFormField(
                id: .routingNumber,
                title: "Routing number",
                placeholder: "000000000000"
            ),
        ]
    }

    // [REDACTED_TODO_COMMENT]
    static func nameFields(isBusiness: Bool) -> [OfframpFormField] {
        if isBusiness {
            return [
                OfframpFormField(
                    id: .businessName,
                    title: "Business name",
                    placeholder: "Eg., Dunder Mifflin LLC"
                ),
            ]
        }

        return [
            OfframpFormField(
                id: .firstName,
                title: "First name",
                placeholder: "John"
            ),
            OfframpFormField(
                id: .lastName,
                title: "Last name",
                placeholder: "Doe"
            ),
        ]
    }

    // [REDACTED_TODO_COMMENT]
    func addressFields() -> [OfframpFormField] {
        [
            OfframpFormField(
                id: .countryCode,
                title: "Country",
                placeholder: "Not selected",
                onSelect: { [weak self] in self?.selectCountry() }
            ),
            OfframpFormField(
                id: .region,
                title: "Region / state",
                placeholder: regionPlaceholder,
                onSelect: isRegionSelectable ? { [weak self] in self?.selectRegion() } : nil
            ),
            OfframpFormField(
                id: .city,
                title: "City",
                placeholder: "Eg., Night City"
            ),
            OfframpFormField(
                id: .line1,
                title: "Address line 1",
                placeholder: "Eg., Ebunike st., Apt. 32"
            ),
            OfframpFormField(
                id: .line2,
                title: "Address line 2",
                placeholder: "Eg., Ebunike st., Apt. 32"
            ),
            OfframpFormField(
                id: .postalCode,
                title: "Postal code",
                placeholder: "0000"
            ),
        ]
    }

    static func restoredValues(
        from details: TangemPayOfframpPersonalDetails
    ) -> [OfframpFormField.ID: String] {
        var values: [OfframpFormField.ID: String] = [
            .accountNumber: details.accountNumber,
            .routingNumber: details.routingNumber,
            .countryCode: details.country.name,
            .region: details.region?.name ?? details.regionText,
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

// MARK: - Geo selection

private extension PersonalDetailsViewModel {
    var isRegionSelectable: Bool {
        country?.code == Constants.regionSelectionCountryCode
    }

    // [REDACTED_TODO_COMMENT]
    var regionPlaceholder: String {
        isRegionSelectable ? "Not selected" : "Eg., Bavaria"
    }

    func selectCountry() {
        output(.selectCountry { [weak self] in self?.apply(country: $0) })
    }

    func selectRegion() {
        guard let country else { return }

        output(.selectRegion(countryCode: country.code) { [weak self] in self?.apply(region: $0) })
    }

    func apply(country selected: TangemPayGeoCountry) {
        let didChange = country?.code != selected.code
        country = selected

        updateField(.countryCode) {
            $0.text = selected.name
            $0.error = nil
        }

        guard didChange else { return }

        region = nil

        let onSelect: (() -> Void)? = isRegionSelectable ? { [weak self] in self?.selectRegion() } : nil
        let placeholder = regionPlaceholder

        updateField(.region) {
            $0.text = ""
            $0.error = nil
            $0.placeholder = placeholder
            $0.onSelect = onSelect
        }
    }

    func apply(region selected: TangemPayGeoRegion) {
        region = selected

        updateField(.region) {
            $0.text = selected.name
            $0.error = nil
        }
    }
}

// MARK: - Constants

private extension PersonalDetailsViewModel {
    enum Constants {
        static let regionSelectionCountryCode = "US"
    }
}

// MARK: - Output

extension PersonalDetailsViewModel {
    enum Output {
        case selectCountry((TangemPayGeoCountry) -> Void)
        case selectRegion(countryCode: String, (TangemPayGeoRegion) -> Void)
        case continueWizard
        case close
    }
}

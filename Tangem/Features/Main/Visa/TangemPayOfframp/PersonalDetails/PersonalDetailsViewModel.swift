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
    @Published private(set) var suggestions: [OfframpAccountSuggestion] = []

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let recentRecipientsStore: TangemPayRecentRecipientsStore
    private let isBusiness: Bool
    private let output: (Output) -> Void

    private var country: TangemPayGeoCountry?
    private var region: TangemPayGeoRegion?
    private var recipients: [TangemPayBankAccountResponse] = []

    private var bag: Set<AnyCancellable> = []

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        recentRecipientsStore: TangemPayRecentRecipientsStore,
        title: String,
        stepSubtitle: String?,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.recentRecipientsStore = recentRecipientsStore
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.output = output

        isBusiness = orderBuilder.recipient == .newBusiness

        refresh()
        bind()
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
        if let blurredFieldID = focusedFieldID, blurredFieldID != id {
            updateField(blurredFieldID) { $0.error = $0.currentError }
        }

        focusedFieldID = id
        updateSuggestions()
    }

    func fieldDidChange(_ id: OfframpFormField.ID) {
        if id == .accountNumber {
            updateSuggestions()
        }

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

    func onSuggestionTap(id: String) {
        recentRecipientsStore.recordSelection(id: id)
        orderBuilder.selectSaved(bankAccountId: id)
        output(.savedRecipientSelected)
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Suggestions

private extension PersonalDetailsViewModel {
    func bind() {
        recentRecipientsStore
            .recipientsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, recipients in
                viewModel.recipients = recipients
                viewModel.updateSuggestions()
            }
            .store(in: &bag)
    }

    func updateSuggestions() {
        guard focusedFieldID == .accountNumber else {
            suggestions = []
            return
        }

        let prefix = text(for: .accountNumber)

        guard !prefix.isEmpty else {
            suggestions = []
            return
        }

        suggestions = Self.makeSuggestions(from: recipients, prefix: prefix)
    }

    static func makeSuggestions(
        from recipients: [TangemPayBankAccountResponse],
        prefix: String
    ) -> [OfframpAccountSuggestion] {
        recipients
            .filter { $0.details.accountNumber.hasPrefix(prefix) }
            .map { bankAccount in
                let accountNumber = bankAccount.details.accountNumber

                return OfframpAccountSuggestion(
                    id: bankAccount.id,
                    matchedPrefix: String(accountNumber.prefix(prefix.count)),
                    accountNumberSuffix: String(accountNumber.dropFirst(prefix.count)),
                    name: TangemPayRecipientNameFormatter.name(for: bankAccount, style: .abbreviated)
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
        output(
            .selectCountry(
                selectedCountryCode: country?.code,
                selectedRegionCode: region?.code
            ) { [weak self] selectedCountry, selectedRegion in
                self?.apply(country: selectedCountry, region: selectedRegion)
            }
        )
    }

    func selectRegion() {
        guard let country else { return }

        output(
            .selectRegion(countryCode: country.code, selectedCode: region?.code) { [weak self] in
                self?.apply(region: $0)
            }
        )
    }

    func apply(country selectedCountry: TangemPayGeoCountry, region selectedRegion: TangemPayGeoRegion?) {
        apply(country: selectedCountry)

        if let selectedRegion {
            apply(region: selectedRegion)
        }
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
        case selectCountry(
            selectedCountryCode: String?,
            selectedRegionCode: String?,
            (TangemPayGeoCountry, TangemPayGeoRegion?) -> Void
        )
        case selectRegion(countryCode: String, selectedCode: String?, (TangemPayGeoRegion) -> Void)
        case savedRecipientSelected
        case continueWizard
        case close
    }
}

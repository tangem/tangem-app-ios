//
//  TransferConfirmationSectionsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemPay

enum TransferConfirmationSectionsBuilder {
    static func sections(
        personalDetails: TangemPayOfframpPersonalDetails?,
        bankDetails: TangemPayOfframpBankDetails?
    ) -> [TransferConfirmationSection] {
        guard let personalDetails else {
            return []
        }

        let bank: [Entry] = bankDetails.map { details in
            [
                Entry(.bankName, details.name),
                Entry(.bankRegion, details.region.name),
                Entry(.bankCity, details.city),
                Entry(.bankLine1, details.line1),
                Entry(.bankPostalCode, details.postalCode),
            ]
        } ?? []

        return make(
            account: [
                Entry(.accountNumber, personalDetails.accountNumber),
                Entry(.routingNumber, personalDetails.routingNumber),
            ],
            beneficiary: nameEntries(for: personalDetails.name) + [
                Entry(.countryCode, personalDetails.country.name),
                Entry(.region, personalDetails.region?.name ?? personalDetails.regionText),
                Entry(.city, personalDetails.city),
                Entry(.line1, personalDetails.line1),
                Entry(.line2, personalDetails.line2),
                Entry(.postalCode, personalDetails.postalCode),
            ],
            bank: bank,
            isEditable: true
        )
    }

    static func sections(savedRecipient: TangemPayBankAccountResponse) -> [TransferConfirmationSection] {
        let details = savedRecipient.details
        let beneficiaryAddress = details.beneficiaryAddress
        let bankAddress = details.bankAddress

        return make(
            account: [
                Entry(.accountNumber, details.accountNumber),
                Entry(.routingNumber, details.routingNumber),
            ],
            beneficiary: nameEntries(for: details.beneficiary) + [
                Entry(.countryCode, beneficiaryAddress?.countryCode),
                Entry(.region, beneficiaryAddress?.region),
                Entry(.city, beneficiaryAddress?.city),
                Entry(.line1, beneficiaryAddress?.line1),
                Entry(.line2, beneficiaryAddress?.line2),
                Entry(.postalCode, beneficiaryAddress?.postalCode),
            ],
            bank: [
                Entry(.bankName, details.bankName),
                Entry(.bankRegion, bankAddress?.region),
                Entry(.bankCity, bankAddress?.city),
                Entry(.bankLine1, bankAddress?.line1),
                Entry(.bankPostalCode, bankAddress?.postalCode),
            ],
            isEditable: false
        )
    }
}

// MARK: - Entry

private extension TransferConfirmationSectionsBuilder {
    struct Entry {
        let id: TangemPayFormField.ID
        let value: String?

        init(_ id: TangemPayFormField.ID, _ value: String?) {
            self.id = id
            self.value = value
        }
    }
}

// MARK: - Assembly

private extension TransferConfirmationSectionsBuilder {
    static func make(
        account: [Entry],
        beneficiary: [Entry],
        bank: [Entry],
        isEditable: Bool
    ) -> [TransferConfirmationSection] {
        [
            section(
                id: .account,
                header: Localization.tangempayWithdrawBankRecipientInfo,
                entries: account,
                editTarget: isEditable ? .personalDetails : nil
            ),
            section(
                id: .beneficiary,
                header: nil,
                entries: beneficiary,
                editTarget: isEditable ? .personalDetails : nil
            ),
            section(
                id: .bank,
                header: nil,
                entries: bank,
                editTarget: isEditable ? .bankDetails : nil
            ),
        ]
        .compactMap { $0 }
    }

    static func section(
        id: TransferConfirmationSection.ID,
        header: String?,
        entries: [Entry],
        editTarget: TransferConfirmationEditTarget?
    ) -> TransferConfirmationSection? {
        let rows = entries.compactMap(row(from:))

        guard rows.isNotEmpty else {
            return nil
        }

        return TransferConfirmationSection(id: id, header: header, rows: rows, editTarget: editTarget)
    }

    static func row(from entry: Entry) -> TransferConfirmationSection.Row? {
        guard let value = entry.value?.trimmed().nilIfEmpty else {
            return nil
        }

        return TransferConfirmationSection.Row(id: entry.id, title: title(for: entry.id), value: value)
    }

    static func nameEntries(for name: TangemPayOfframpPersonalDetails.Name) -> [Entry] {
        switch name {
        case .individual(let firstName, let lastName):
            [Entry(.firstName, firstName), Entry(.lastName, lastName)]
        case .business(let businessName):
            [Entry(.businessName, businessName)]
        }
    }

    static func nameEntries(for beneficiary: TangemPayBankAccountResponse.Beneficiary) -> [Entry] {
        switch beneficiary.type {
        case .business:
            [Entry(.businessName, beneficiary.businessName)]
        case .individual, .none:
            [Entry(.firstName, beneficiary.firstName), Entry(.lastName, beneficiary.lastName)]
        }
    }
}

// MARK: - Titles

private extension TransferConfirmationSectionsBuilder {
    static func title(for id: TangemPayFormField.ID) -> String {
        switch id {
        case .email: Localization.tangempayOrderDataEmail
        case .accountNumber: Localization.tangempayWithdrawBankFieldAccountNumber
        case .routingNumber: Localization.tangempayWithdrawBankFieldRoutingNumber
        case .firstName: Localization.tangempayOrderDataFirstName
        case .lastName: Localization.tangempayOrderDataLastName
        case .businessName: Localization.tangempayWithdrawBankFieldBusinessName
        case .countryCode: Localization.tangempayOrderDataCountry
        case .region: Localization.tangempayOrderDataRegion
        case .city: Localization.tangempayOrderDataCity
        case .line1: Localization.tangempayOrderDataAddressLine1
        case .line2: Localization.tangempayOrderDataAddressLine2
        case .postalCode: Localization.tangempayOrderDataPostalCode
        case .bankName: Localization.tangempayWithdrawBankFieldBankName
        case .bankRegion: Localization.tangempayWithdrawBankFieldBankRegion
        case .bankCity: Localization.tangempayWithdrawBankFieldBankCity
        case .bankLine1: Localization.tangempayWithdrawBankFieldBankAddressLine1
        case .bankPostalCode: Localization.tangempayOrderDataPostalCode
        }
    }
}

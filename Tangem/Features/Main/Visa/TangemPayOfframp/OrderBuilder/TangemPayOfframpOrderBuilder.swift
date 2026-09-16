//
//  TangemPayOfframpOrderBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

final class TangemPayOfframpOrderBuilder {
    static let bankCountryCode = "US"

    private(set) var recipient: TangemPayOfframpRecipient
    private(set) var amount: Decimal?
    private(set) var token: TangemPayOfframpTokenSelection?
    private(set) var rail: TangemPayBankAccountRail?
    private(set) var isThirdParty: Bool?
    private(set) var accountType: TangemPayBankAccountType?
    private(set) var personalDetails: TangemPayOfframpPersonalDetails?
    private(set) var bankDetails: TangemPayOfframpBankDetails?

    init(recipient: TangemPayOfframpRecipient) {
        self.recipient = recipient

        if recipient == .newBusiness {
            isThirdParty = Constants.businessThirdParty
        }
    }

    func set(amount: Decimal) {
        self.amount = amount
    }

    func set(token: TangemPayOfframpTokenSelection) {
        self.token = token
    }

    func set(rail: TangemPayBankAccountRail) {
        self.rail = rail
    }

    func set(isThirdParty: Bool) {
        self.isThirdParty = isThirdParty
    }

    func set(accountType: TangemPayBankAccountType) {
        self.accountType = accountType
    }

    func set(personalDetails: TangemPayOfframpPersonalDetails) {
        self.personalDetails = personalDetails
    }

    func set(bankDetails: TangemPayOfframpBankDetails) {
        self.bankDetails = bankDetails
    }

    func selectSaved(bankAccountId: String) {
        recipient = .saved(bankAccountId: bankAccountId)
        isThirdParty = nil
        accountType = nil
        personalDetails = nil
        bankDetails = nil
    }

    func buildOrderRequest() throws(BuildError) -> TangemPayPlaceOrderRequest {
        guard let amount else {
            throw .missingAmount
        }

        guard let token else {
            throw .missingToken
        }

        let amountInCents = TangemPayUtilities.fiatItem
            .convertToCents(value: amount)
            .intValue(roundingMode: .down)

        switch recipient {
        case .saved(let bankAccountId):
            return TangemPayPlaceOrderRequest(
                offrampAmountInCents: amountInCents,
                chainId: token.chainId,
                tokenContractAddress: token.tokenContractAddress,
                bankAccountId: bankAccountId
            )

        case .newIndividual, .newBusiness:
            guard let isThirdParty else {
                throw .missingTransferType
            }

            return try makeNewBankAccountRequest(
                amountInCents: amountInCents,
                token: token,
                thirdParty: isThirdParty
            )
        }
    }
}

// MARK: - Mode B assembly

private extension TangemPayOfframpOrderBuilder {
    func makeNewBankAccountRequest(
        amountInCents: Int,
        token: TangemPayOfframpTokenSelection,
        thirdParty: Bool
    ) throws(BuildError) -> TangemPayPlaceOrderRequest {
        guard let rail else {
            throw .missingRail
        }

        guard let personalDetails else {
            throw .missingPersonalDetails
        }

        guard let bankDetails else {
            throw .missingBankDetails
        }

        guard let accountType else {
            throw .missingAccountType
        }

        let details = TangemPayPlaceOrderRequest.BankAccount.Details(
            currency: Constants.currency,
            rail: rail,
            thirdParty: thirdParty,
            beneficiary: Self.makeBeneficiary(from: personalDetails.name),
            beneficiaryAddress: .init(
                line1: personalDetails.line1,
                line2: personalDetails.line2,
                city: personalDetails.city,
                region: personalDetails.region.map {
                    Self.requestRegionCode($0, countryCode: personalDetails.country.code)
                } ?? personalDetails.regionText,
                postalCode: personalDetails.postalCode,
                countryCode: personalDetails.country.code
            ),
            bankName: bankDetails.name,
            bankAddress: .init(
                line1: bankDetails.line1,
                line2: nil,
                city: bankDetails.city,
                region: Self.requestRegionCode(bankDetails.region, countryCode: Self.bankCountryCode),
                postalCode: bankDetails.postalCode,
                countryCode: Self.bankCountryCode
            ),
            accountNumber: personalDetails.accountNumber,
            routingNumber: personalDetails.routingNumber,
            bankAccountType: accountType
        )

        return TangemPayPlaceOrderRequest(
            offrampAmountInCents: amountInCents,
            chainId: token.chainId,
            tokenContractAddress: token.tokenContractAddress,
            bankAccount: .init(displayName: nil, details: details)
        )
    }

    static func requestRegionCode(_ region: TangemPayGeoRegion, countryCode: String) -> String {
        let prefix = countryCode + "-"

        guard region.code.hasPrefix(prefix) else {
            return region.code
        }

        return String(region.code.dropFirst(prefix.count))
    }

    static func makeBeneficiary(
        from name: TangemPayOfframpPersonalDetails.Name
    ) -> TangemPayPlaceOrderRequest.BankAccount.Beneficiary {
        switch name {
        case .individual(let firstName, let lastName):
            .individual(firstName: firstName, lastName: lastName)
        case .business(let name):
            .business(name: name)
        }
    }
}

// MARK: - BuildError

extension TangemPayOfframpOrderBuilder {
    enum BuildError: Error, Equatable {
        case missingAmount
        case missingToken
        case missingRail
        case missingTransferType
        case missingPersonalDetails
        case missingBankDetails
        case missingAccountType
    }
}

// MARK: - Constants

private extension TangemPayOfframpOrderBuilder {
    enum Constants {
        static let currency = "USD"
        static let businessThirdParty = true
    }
}

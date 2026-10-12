//
//  TangemPayPlaceOrderRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayPlaceOrderRequest: Encodable {
    public static let virtualAccountSpecificationName = "SP_000006"

    public let data: Data

    public init(type: String, customerWalletAddress: String, specificationName: String) {
        data = Data(
            type: type,
            specificationName: specificationName,
            customerWalletAddress: customerWalletAddress
        )
    }

    /// Co-brand campaign card issue. `type` and `specificationName` come from the campaign's entry in
    /// `customer/offers?deeplink_value=`; `deeplinkValue` is what tells the issuer which art to stamp.
    public init(
        type: String,
        customerWalletAddress: String,
        specificationName: String,
        deeplinkValue: String
    ) {
        data = Data(
            type: type,
            specificationName: specificationName,
            customerWalletAddress: customerWalletAddress,
            deeplinkValue: deeplinkValue
        )
    }

    /// Virtual Account issue order (`ACCOUNT_ISSUE_VIRTUAL_RAIN`). The VA is bound to the card's
    /// existing collateral contract, so nothing is derived on the client and no `wallet_address` is
    /// sent: `depositAddress` is the card's existing collateral (deposit) address.
    public init(depositAddress: String) {
        data = Data(
            type: TangemPayOrderType.accountIssueVirtualRain.rawValue,
            specificationName: TangemPayPlaceOrderRequest.virtualAccountSpecificationName,
            depositAddress: depositAddress
        )
    }

    /// Tariff plan transition order (`TARIFF_PLAN_TRANSITION`). Used on plan selection during
    /// onboarding and on upgrade: PA and PI are created inside the order. `transitionType` is the
    /// raw value of `TangemPayTariffPlanTransition.TransitionType` (`ACTIVATION` / `UPGRADE` / `DOWNGRADE`).
    public init(targetTariffPlanId: String, transitionType: String, customerWalletAddress: String) {
        data = Data(
            type: TangemPayOrderType.tariffPlanTransition.rawValue,
            customerWalletAddress: customerWalletAddress,
            targetTariffPlanId: targetTariffPlanId,
            tariffPlanTransitionType: transitionType
        )
    }

    public init(networkContractChainId: Int) {
        data = Data(
            type: TangemPayOrderType.smartContractIssueRain.rawValue,
            chainId: networkContractChainId
        )
    }

    public init(
        customerWalletAddress: String,
        specificationName: String,
        embossName: String,
        shippingAddress: ShippingAddress
    ) {
        data = Data(
            type: TangemPayOrderType.cardIssuePlasticRain.rawValue,
            specificationName: specificationName,
            customerWalletAddress: customerWalletAddress,
            embossName: embossName,
            shippingAddress: shippingAddress
        )
    }

    public init(
        offrampAmountInCents: Int,
        chainId: Int,
        tokenContractAddress: String,
        bankAccountId: String
    ) {
        data = Data(
            type: TangemPayOrderType.bankOfframpRain.rawValue,
            chainId: chainId,
            amountInCents: offrampAmountInCents,
            tokenContractAddress: tokenContractAddress,
            bankAccountId: bankAccountId
        )
    }

    public init(
        offrampAmountInCents: Int,
        chainId: Int,
        tokenContractAddress: String,
        bankAccount: BankAccount
    ) {
        data = Data(
            type: TangemPayOrderType.bankOfframpRain.rawValue,
            chainId: chainId,
            amountInCents: offrampAmountInCents,
            tokenContractAddress: tokenContractAddress,
            bankAccount: bankAccount
        )
    }

    public init(customerWalletAddress: String, productInstanceId: String, lastFourDigits: String) {
        data = Data(
            type: TangemPayOrderType.cardActivationPlasticRain.rawValue,
            customerWalletAddress: customerWalletAddress,
            productInstanceId: productInstanceId,
            lastFourDigits: lastFourDigits
        )
    }

    public init(
        customerWalletAddress: String,
        sourceProductInstanceId: String,
        embossName: String,
        shippingAddress: ShippingAddress
    ) {
        data = Data(
            type: TangemPayOrderType.cardReissuePlasticRain.rawValue,
            customerWalletAddress: customerWalletAddress,
            embossName: embossName,
            shippingAddress: shippingAddress,
            sourceProductInstanceId: sourceProductInstanceId
        )
    }
}

public extension TangemPayPlaceOrderRequest {
    struct ShippingAddress: Encodable {
        public let firstName: String
        public let lastName: String
        public let line1: String
        public let line2: String?
        public let city: String
        public let region: String
        public let postalCode: String
        public let phoneNumber: String

        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case line1
            case line2
            case city
            case region
            case postalCode = "postal_code"
            case phoneNumber = "phone_number"
        }

        public init(
            firstName: String,
            lastName: String,
            line1: String,
            line2: String?,
            city: String,
            region: String,
            postalCode: String,
            phoneNumber: String
        ) {
            self.firstName = firstName
            self.lastName = lastName
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.region = region
            self.postalCode = postalCode
            self.phoneNumber = phoneNumber
        }

        public var idempotencyComponent: String {
            [firstName, lastName, line1, line2 ?? "", city, region, postalCode, phoneNumber]
                .joined(separator: "|")
        }
    }
}

public extension TangemPayPlaceOrderRequest {
    struct BankAccount: Encodable {
        public let displayName: String?
        public let details: Details

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case details
        }

        public init(displayName: String?, details: Details) {
            self.displayName = displayName
            self.details = details
        }
    }
}

public extension TangemPayPlaceOrderRequest.BankAccount {
    struct Details: Encodable {
        public let currency: String
        public let rail: TangemPayBankAccountRail
        public let thirdParty: Bool
        public let beneficiary: Beneficiary
        public let beneficiaryAddress: Address
        public let bankName: String
        public let bankAddress: Address
        public let accountNumber: String
        public let routingNumber: String
        public let bankAccountType: TangemPayBankAccountType

        enum CodingKeys: String, CodingKey {
            case currency
            case rail
            case thirdParty = "third_party"
            case beneficiary
            case beneficiaryAddress = "beneficiary_address"
            case bankName = "bank_name"
            case bankAddress = "bank_address"
            case accountNumber = "account_number"
            case routingNumber = "routing_number"
            case bankAccountType = "bank_account_type"
        }

        public init(
            currency: String,
            rail: TangemPayBankAccountRail,
            thirdParty: Bool,
            beneficiary: Beneficiary,
            beneficiaryAddress: Address,
            bankName: String,
            bankAddress: Address,
            accountNumber: String,
            routingNumber: String,
            bankAccountType: TangemPayBankAccountType
        ) {
            self.currency = currency
            self.rail = rail
            self.thirdParty = thirdParty
            self.beneficiary = beneficiary
            self.beneficiaryAddress = beneficiaryAddress
            self.bankName = bankName
            self.bankAddress = bankAddress
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.bankAccountType = bankAccountType
        }
    }

    struct Beneficiary: Encodable {
        public let type: TangemPayBankAccountBeneficiaryType
        public let firstName: String?
        public let lastName: String?
        public let businessName: String?

        enum CodingKeys: String, CodingKey {
            case type
            case firstName = "first_name"
            case lastName = "last_name"
            case businessName = "business_name"
        }

        public static func individual(firstName: String, lastName: String) -> Self {
            Self(type: .individual, firstName: firstName, lastName: lastName, businessName: nil)
        }

        public static func business(name: String) -> Self {
            Self(type: .business, firstName: nil, lastName: nil, businessName: name)
        }
    }

    struct Address: Encodable {
        public let line1: String
        public let line2: String?
        public let city: String
        public let region: String
        public let postalCode: String
        public let countryCode: String

        enum CodingKeys: String, CodingKey {
            case line1
            case line2
            case city
            case region
            case postalCode = "postal_code"
            case countryCode = "country_code"
        }

        public init(
            line1: String,
            line2: String?,
            city: String,
            region: String,
            postalCode: String,
            countryCode: String
        ) {
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.region = region
            self.postalCode = postalCode
            self.countryCode = countryCode
        }
    }
}

public extension TangemPayPlaceOrderRequest {
    struct Data: Encodable {
        public let type: String
        public let specificationName: String?
        public let customerWalletAddress: String?
        public let depositAddress: String?
        public let targetTariffPlanId: String?
        public let tariffPlanTransitionType: String?
        public let chainId: Int?
        public let embossName: String?
        public let shippingAddress: ShippingAddress?
        public let productInstanceId: String?
        public let sourceProductInstanceId: String?
        public let lastFourDigits: String?
        public let amountInCents: Int?
        public let tokenContractAddress: String?
        public let bankAccountId: String?
        public let bankAccount: BankAccount?
        public let deeplinkValue: String?

        enum CodingKeys: String, CodingKey {
            case type
            case specificationName = "specification_name"
            case customerWalletAddress = "customer_wallet_address"
            case depositAddress = "deposit_address"
            case targetTariffPlanId = "target_tariff_plan_id"
            case tariffPlanTransitionType = "tariff_plan_transition_type"
            case chainId = "chain_id"
            case embossName = "emboss_name"
            case shippingAddress = "shipping_address"
            case productInstanceId = "product_instance_id"
            case sourceProductInstanceId = "source_product_instance_id"
            case lastFourDigits = "last_four_digits"
            case amountInCents = "amount_in_cents"
            case tokenContractAddress = "token_contract_address"
            case bankAccountId = "bank_account_id"
            case bankAccount = "bank_account"
            case deeplinkValue = "deeplink_value"
        }

        init(
            type: String,
            specificationName: String? = nil,
            customerWalletAddress: String? = nil,
            depositAddress: String? = nil,
            targetTariffPlanId: String? = nil,
            tariffPlanTransitionType: String? = nil,
            chainId: Int? = nil,
            embossName: String? = nil,
            shippingAddress: ShippingAddress? = nil,
            productInstanceId: String? = nil,
            sourceProductInstanceId: String? = nil,
            lastFourDigits: String? = nil,
            amountInCents: Int? = nil,
            tokenContractAddress: String? = nil,
            bankAccountId: String? = nil,
            bankAccount: BankAccount? = nil,
            deeplinkValue: String? = nil
        ) {
            self.type = type
            self.specificationName = specificationName
            self.customerWalletAddress = customerWalletAddress
            self.depositAddress = depositAddress
            self.targetTariffPlanId = targetTariffPlanId
            self.tariffPlanTransitionType = tariffPlanTransitionType
            self.chainId = chainId
            self.embossName = embossName
            self.shippingAddress = shippingAddress
            self.productInstanceId = productInstanceId
            self.sourceProductInstanceId = sourceProductInstanceId
            self.lastFourDigits = lastFourDigits
            self.amountInCents = amountInCents
            self.tokenContractAddress = tokenContractAddress
            self.bankAccountId = bankAccountId
            self.bankAccount = bankAccount
            self.deeplinkValue = deeplinkValue
        }
    }
}

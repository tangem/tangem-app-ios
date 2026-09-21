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
            lastFourDigits: String? = nil
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
        }
    }
}

//
//  CheckoutPayload.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

protocol CheckoutPayload {
    var checkout: Storefront.Checkout? { get }
    var checkoutUserErrors: [Storefront.CheckoutUserError] { get }
}

extension Storefront.CheckoutLineItemsReplacePayload: CheckoutPayload {
    var checkoutUserErrors: [Storefront.CheckoutUserError] { self.userErrors }
}

extension Storefront.CheckoutCreatePayload: CheckoutPayload { }

extension Storefront.CheckoutDiscountCodeApplyV2Payload: CheckoutPayload { }

extension Storefront.CheckoutDiscountCodeRemovePayload: CheckoutPayload { }

extension Storefront.CheckoutShippingAddressUpdateV2Payload: CheckoutPayload { }

extension Storefront.CheckoutEmailUpdateV2Payload: CheckoutPayload { }

extension Storefront.CheckoutShippingLineUpdatePayload: CheckoutPayload { }

extension Storefront.CheckoutCompleteWithTokenizedPaymentV3Payload: CheckoutPayload { }

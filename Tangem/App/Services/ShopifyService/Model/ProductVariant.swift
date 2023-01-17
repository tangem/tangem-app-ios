//
//  ProductVariant.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

struct ProductVariant {
    let id: GraphQL.ID
    let sku: String?
    let title: String
    let amount: Decimal
    let originalAmount: Decimal?
    let currencyCode: String

    let product: Product
}

extension ProductVariant {
    init(_ productVariant: Storefront.ProductVariant) {
        id = productVariant.id
        sku = productVariant.sku
        title = productVariant.title
        amount = productVariant.priceV2.amount
        originalAmount = productVariant.compareAtPriceV2?.amount
        currencyCode = productVariant.priceV2.currencyCode.rawValue

        product = Product(productVariant.product)
    }
}

extension Storefront.ProductVariantQuery {
    @discardableResult
    func productVariantFieldsFragment() -> Storefront.ProductVariantQuery {
        id()
            .sku()
            .title()
            .priceV2 { $0
                .amount()
                .currencyCode()
            }
            .compareAtPriceV2 { $0
                .amount()
            }
            .product { $0
                .productFieldsFragment(includeVariants: false)
            }
    }
}

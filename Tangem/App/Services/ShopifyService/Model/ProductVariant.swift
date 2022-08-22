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
        self.id = productVariant.id
        self.sku = productVariant.sku
        self.title = productVariant.title
        self.amount = productVariant.priceV2.amount
        self.originalAmount = productVariant.compareAtPriceV2?.amount
        self.currencyCode = productVariant.priceV2.currencyCode.rawValue

        self.product = Product(productVariant.product)
    }
}

extension Storefront.ProductVariantQuery {
    @discardableResult
    func productVariantFieldsFragment() -> Storefront.ProductVariantQuery {
        self
            .id()
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

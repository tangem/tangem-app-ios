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
    let notInStock: Bool
    let amount: Decimal
    let originalAmount: Decimal?
    let currencyCode: String
    
    let product: Product

    init(id: GraphQL.ID, sku: String, title: String, notInStock: Bool, amount: Decimal, originalAmount: Decimal?, currencyCode: String, product: Product) {
        self.id = id
        self.sku = sku
        self.title = title
        self.notInStock = notInStock
        self.amount = amount
        self.originalAmount = originalAmount
        self.currencyCode = currencyCode

        self.product = product
    }
    
    init(_ productVariant: Storefront.ProductVariant) {
        self.id = productVariant.id
        self.sku = productVariant.sku
        self.title = productVariant.title
        self.notInStock = productVariant.currentlyNotInStock
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
            .currentlyNotInStock()
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

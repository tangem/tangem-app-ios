//
//  Product.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

struct Product {
    let id: GraphQL.ID
    let title: String
    let variants: [ProductVariant]
}

extension Product {
    init(_ product: Storefront.Product) {
        id = product.id
        title = product.title
        if product.fields["variants"] != nil {
            variants = product.variants.edges.map { .init($0.node) }
        } else {
            variants = []
        }
    }
}

extension Storefront.ProductQuery {
    @discardableResult
    func productFieldsFragment(includeVariants: Bool = true) -> Storefront.ProductQuery {
        var query = id()
            .title()

        if includeVariants {
            query = query
                .variants(first: 250) { $0
                    .edges { $0
                        .node { $0
                            .productVariantFieldsFragment()
                        }
                    }
                }
        }

        return query
    }
}

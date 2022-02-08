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
    let available: Bool
    let imageUrl: URL?
    let variants: [ProductVariant]
    
    init(id: GraphQL.ID, title: String, available: Bool, imageUrl: URL?, variants: [ProductVariant]) {
        self.id = id
        self.title = title
        self.available = available
        self.imageUrl = imageUrl
        self.variants = variants
    }

    init(_ product: Storefront.Product) {
        self.id = product.id
        self.title = product.title
        self.available = product.availableForSale
        self.imageUrl = product.images.edges.first?.node.originalSrc
        if product.fields["variants"] != nil {
            self.variants = product.variants.edges.map { .init($0.node) }
        } else {
            self.variants = []
        }
    }
}

#warning("TODO")
extension Storefront.ProductQuery {
    @discardableResult
    func productFieldsFragment(includeVariants: Bool = true) -> Storefront.ProductQuery {
        var query = self
            .id()
            .title()
//            .description()
//            .descriptionHtml()
            .images(first: 1) { $0
                .edges { $0
                    .node { $0
                        .id()
                        .originalSrc()
                    }
                }
            }
            .availableForSale()
        
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

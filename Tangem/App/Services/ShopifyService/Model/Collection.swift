//
//  Collection.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import MobileBuySDK

struct Collection {
    let title: String
    let products: [Product]
    
    init(title: String, products: [Product]) {
        self.title = title
        self.products = products
    }
    
    init(_ collection: Storefront.Collection) {
        self.title = collection.title
        self.products = collection.products.edges.map { .init($0.node) }
    }
}

extension Storefront.CollectionQuery {
    @discardableResult
    func collectionFieldsFragment() -> Storefront.CollectionQuery {
        self
            .title()
            .products(first: 250) { $0
                .edges { $0
                    .node { $0
                        .productFieldsFragment()
                    }
                }
            }
    }
}

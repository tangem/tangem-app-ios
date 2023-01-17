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
}

extension Collection {
    init(_ collection: Storefront.Collection) {
        title = collection.title
        products = collection.products.edges.map { .init($0.node) }
    }
}

extension Storefront.CollectionQuery {
    @discardableResult
    func collectionFieldsFragment() -> Storefront.CollectionQuery {
        title()
            .products(first: 250) { $0
                .edges { $0
                    .node { $0
                        .productFieldsFragment()
                    }
                }
            }
    }
}

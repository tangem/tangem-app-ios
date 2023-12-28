//
//  ExpressProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressProvider: Hashable {
    public typealias Id = String

    public let id: Id
    public let name: String
    public let type: ExpressProviderType
    public let imageURL: URL?
    public let termsOfUse: URL?
    public let privacyPolicy: URL?
}

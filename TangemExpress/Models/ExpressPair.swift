//
//  ExpressPair.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressPair: Hashable {
    public let source: ExpressCurrency
    public let destination: ExpressCurrency
    public let providers: [ExpressProvider.Id]
}

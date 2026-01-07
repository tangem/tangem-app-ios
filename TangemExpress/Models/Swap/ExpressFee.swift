//
//  ExpressFee.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFee {
    public let option: Option
    public let fee: Fee

    public init(option: Option, fee: Fee) {
        self.option = option
        self.fee = fee
    }
}

public extension ExpressFee {
//    enum Variants {
//        case single(Fee)
//        case double(market: Fee, fast: Fee)
//
//        func fee(option: Option) -> Fee {
//            switch (self, option) {
//            case (.double(_, let fast), .fast): fast
//            case (.double(let market, _), .market): market
//            case (.single(let fee), _): fee
//            }
//        }
//    }

    enum Option: Hashable {
        case market
        case fast
    }
}

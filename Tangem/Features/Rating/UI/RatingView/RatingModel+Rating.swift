//
//  RatingModel+Rating.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension RatingModel {
    enum Rating: Int, CaseIterable {
        case one = 1
        case two
        case three
        case four
        case five

        init?(_ string: String?) {
            guard let string, let intValue = Int(string) else { return nil }
            self.init(rawValue: intValue)
        }
    }
}

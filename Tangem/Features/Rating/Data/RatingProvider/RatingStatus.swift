//
//  RatingStatus.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum RatingStatus: Equatable, Sendable {
    case unknown
    case notRated
    case rated(ExistingRating)
}

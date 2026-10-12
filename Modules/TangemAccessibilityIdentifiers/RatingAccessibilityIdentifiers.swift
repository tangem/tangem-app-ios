//
//  RatingAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum RatingAccessibilityIdentifiers {
    public static let block = "ratingBlock"
    public static let feedbackInput = "ratingFeedbackInput"
    public static let submitFeedbackButton = "ratingSubmitFeedbackButton"

    public static func star(_ rating: Int) -> String {
        "ratingStar_\(rating)"
    }
}

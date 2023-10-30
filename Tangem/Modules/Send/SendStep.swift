//
//  SendStep.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

enum SendStep {
    case amount
    case destination
    case fee
    case summary
}

extension SendStep {
    var name: String {
        switch self {
        case .amount:
            "Send"
        case .destination:
            "Recipient"
        case .fee:
            "Speed and Fee"
        case .summary:
            "Send"
        }
    }

    var nextStep: SendStep? {
        switch self {
        case .amount:
            return .destination
        case .destination:
            return .fee
        case .fee:
            return .summary
        case .summary:
            return nil
        }
    }

    var previousStep: SendStep? {
        switch self {
        case .amount:
            return nil
        case .destination:
            return .amount
        case .fee:
            return .destination
        case .summary:
            return .fee
        }
    }
}

//
//  SendSummaryRoutable.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

protocol SendSummaryRoutable {
    func openStep(_ step: SendStep)
    func send()
}

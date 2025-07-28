//
//  SNSEvent+KYCStep.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#if ALPHA || BETA || DEBUG
import IdensicMobileSDK

// [REDACTED_TODO_COMMENT]
// [REDACTED_INFO]
extension SNSEvent {
    var kycStep: KYCStep? {
        switch eventType {
        case .stepInitiated:
            parseStepInitiatedPayload()
        case .analytics:
            parseAnalyticsPayload()
        default:
            nil
        }
    }

    private func parseStepInitiatedPayload() -> KYCStep? {
        guard let screenName = payload[SNSEventKey.idDocSetType] as? String else {
            return nil
        }

        return KYCStep(rawValue: screenName.lowercased())
    }

    private func parseAnalyticsPayload() -> KYCStep? {
        guard payload[SNSEventKey.eventName] as? String == Constants.screenOpenedEventName,
              let dict = payload[SNSEventKey.eventPayload] as? [String: Any]
        else {
            return nil
        }

        if let stepName = dict[Constants.stepNameKey] as? String,
           let step = KYCStep(rawValue: (stepName as String).lowercased()) {
            return step
        }

        if let screenName = dict[Constants.screenNameKey] as? String,
           let step = KYCStep(rawValue: screenName.replacingOccurrences(of: Constants.screenNameSuffix, with: "")) {
            return step
        }

        return nil
    }
}

private enum Constants {
    static let screenOpenedEventName = "user:opened:screen"

    static let stepNameKey = "stepName"
    static let screenNameKey = "screenName"

    static let screenNameSuffix = "Screen"
}
#endif // ALPHA || BETA || DEBUG

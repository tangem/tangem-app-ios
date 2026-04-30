//
//  AnalyticsLoggingSpy.swift
//  TangemTests
//
//  Created for CommonSendAnalyticsLogger unit tests.
//

@testable import Tangem

final class AnalyticsLoggingSpy: AnalyticsLogging {
    struct Call: Equatable {
        let event: Analytics.Event
        let params: [Analytics.ParameterKey: String]
        let analyticsSystems: [Analytics.AnalyticsSystem]
    }

    private(set) var calls: [Call] = []

    func log(
        event: Analytics.Event,
        params: [Analytics.ParameterKey: String],
        analyticsSystems: [Analytics.AnalyticsSystem]
    ) {
        calls.append(Call(event: event, params: params, analyticsSystems: analyticsSystems))
    }
}

//
//  OTLPConfiguration.swift
//  TangemOpenTelemetry
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OTLPConfiguration {
    /// Without the signal path, e.g. `https://otlp.tangem.org`.
    public let baseURL: URL
    public let apiKey: String
    public let serviceName: String
    public let serviceVersion: String
    public let environment: String
    public let osName: String
    public let osVersion: String
    /// ISO 639-1. `nil` keeps the attribute out of the resource.
    public let language: String?
    /// ISO 3166-1 alpha-2. `nil` keeps the attribute out of the resource.
    public let countryCode: String?
    public let exportInterval: TimeInterval
    public let timeout: TimeInterval
    public let session: URLSession

    public init(
        baseURL: URL,
        apiKey: String,
        serviceName: String,
        serviceVersion: String,
        environment: String,
        osName: String,
        osVersion: String,
        language: String?,
        countryCode: String?,
        session: URLSession,
        exportInterval: TimeInterval = 300,
        timeout: TimeInterval = 10
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.serviceName = serviceName
        self.serviceVersion = serviceVersion
        self.environment = environment
        self.osName = osName
        self.osVersion = osVersion
        self.language = language
        self.countryCode = countryCode
        self.session = session
        self.exportInterval = exportInterval
        self.timeout = timeout
    }

    var metricsURL: URL {
        baseURL.appending(path: "v1/metrics", directoryHint: .notDirectory)
    }
}

//
//  HostAnalyticsFormatterUtil.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A utility for formatting hostnames and URLs for analytics tracking.
///
/// `HostAnalyticsFormatterUtil` converts raw host strings or full URLs into
/// normalized, analytics-friendly representations. The formatted output uses
/// underscores as separators and includes the scheme, host, port, and path components.
///
/// Example:
/// ```swift
/// let formatted = HostAnalyticsFormatterUtil().formattedHost(from: "https://api.example.com:8080/v1/endpoint")
/// // formatted -> "https_api_example_com_8080_v1_endpoint"
/// ```
public struct HostAnalyticsFormatterUtil {
    // MARK: - Init

    public init() {}

    // MARK: - Implementation

    /// Formats the provided raw string into an analytics-friendly representation.
    ///
    /// - Parameter raw: The raw string containing a hostname or URL.
    /// - Returns: A formatted version of the host string with normalized format
    ///   using underscores as separators.
    public func formattedHost(from raw: String) -> String {
        let lowercased = raw.lowercased()

        guard let url = URL(string: lowercased), url.scheme != nil else {
            return formatted(hostname: lowercased)
        }

        return formatted(url: url)
    }

    // MARK: - Internal Helpers

    /// Formats a full URL by converting its components into a normalized string
    /// suitable for analytics tracking.
    ///
    /// Example:
    /// ```
    /// https://api.example.com:8080/v1/endpoint -> https_api_example_com_8080_v1_endpoint
    /// ```
    ///
    /// - Parameter url: The `URL` object to format.
    /// - Returns: A formatted, normalized string for analytics.
    private func formatted(url: URL) -> String {
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        var result: [String] = [url.scheme ?? "unresolved_scheme"]
        result.append((url.host ?? "").replacingOccurrences(of: ".", with: Constants.replacementCharacter))

        if let port = url.port {
            result.append(String(port))
        }

        if !pathComponents.isEmpty {
            result.append(pathComponents.joined(separator: Constants.replacementCharacter))
        }

        return result.joined(separator: Constants.replacementCharacter)
    }

    /// Formats a hostname string (without scheme) for analytics tracking.
    ///
    /// Example:
    /// ```
    /// "my-host.domain.com" -> "https_my-host_domain_com"
    /// ```
    ///
    /// - Parameter hostname: A raw hostname string.
    /// - Returns: A formatted hostname string suitable for analytics.
    private func formatted(hostname: String) -> String {
        let formattedHostname = hostname.replacingOccurrences(of: ".", with: Constants.replacementCharacter)

        if formattedHostname.contains(Constants.replacementCharacter), !formattedHostname.hasPrefix("http") {
            return "https\(Constants.replacementCharacter)" + formattedHostname
        }

        return formattedHostname
    }
}

private extension HostAnalyticsFormatterUtil {
    enum Constants {
        static let allowedSetCharacterSet: CharacterSet = .init(charactersIn: "-_")
        static let replacementCharacter: String = "_"
    }
}

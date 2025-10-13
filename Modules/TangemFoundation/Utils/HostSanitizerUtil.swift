//
//  HostSanitizerUtil.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A utility for sanitizing and masking hostnames or URLs.
///
/// `HostSanitizerUtil` converts raw host strings or full URLs into safe,
/// normalized representations suitable for logging. Sensitive data such as
/// potential API keys in path components will be masked with `***`.
///
/// Example:
/// ```swift
/// let safe = HostSanitizerUtil().sanitizedHost(from: "https://api.example.com/v1/abcdef1234567890KEYSECRET123456")
/// // safe -> "https_api_example_com_v1_***"
/// ```
public struct HostSanitizerUtil {
    // MARK: - Init

    public init() {}

    // MARK: - Implementation

    /// Returns a sanitized and safe version of the provided raw string,
    /// which can be used safely in logs without leaking sensitive data.
    ///
    /// - Parameter raw: The raw string containing a hostname or URL.
    /// - Returns: A sanitized version of the host string with normalized format
    ///   and masked API keys (if detected).
    public func sanitizedHost(from raw: String) -> String {
        let lowercased = raw.lowercased()

        guard let url = URL(string: lowercased), url.scheme != nil else {
            return sanitize(hostname: lowercased)
        }

        return sanitize(url: url)
    }

    // MARK: - Internal Helpers

    /// Sanitizes a full URL by converting its host into a normalized string
    /// and masking API key–like path components.
    ///
    /// Example:
    /// ```
    /// https://api.example.com/v1/KEY123... -> https_api_example_com_v1_***
    /// ```
    ///
    /// - Parameter url: The `URL` object to sanitize.
    /// - Returns: A safe, normalized string.
    private func sanitize(url: URL) -> String {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let sanitizedComponents = pathComponents.map { isLikelyAPIKey($0) ? Constants.maskAPIKeyCharacter : $0 }

        var result: [String] = [url.scheme ?? "unresolved_scheme"]
        result.append((url.host ?? "").replacingOccurrences(of: ".", with: Constants.replacementCharacter))

        if let port = url.port {
            result.append(String(port))
        }

        if !sanitizedComponents.isEmpty {
            result.append(sanitizedComponents.joined(separator: Constants.replacementCharacter))
        }

        return result.joined(separator: Constants.replacementCharacter)
    }

    /// Sanitizes a hostname string (without scheme).
    ///
    /// Example:
    /// ```
    /// "my-host.domain.com" -> "https_my-host_domain_com"
    /// ```
    ///
    /// - Parameter hostname: A raw hostname string.
    /// - Returns: A normalized hostname string safe for logging.
    private func sanitize(hostname: String) -> String {
        let sanitized = hostname.replacingOccurrences(of: ".", with: Constants.replacementCharacter)

        if sanitized.contains(Constants.replacementCharacter), !sanitized.hasPrefix("http") {
            return "https\(Constants.replacementCharacter)" + sanitized
        }

        return sanitized
    }

    /// Determines if the provided string is likely an API key.
    ///
    /// Criteria:
    /// - Length of 20 characters or more.
    /// - Contains only alphanumeric characters, dashes (`-`), or underscores (`_`).
    ///
    /// - Parameter string: The string to analyze.
    /// - Returns: `true` if the string is likely an API key, `false` otherwise.
    private func isLikelyAPIKey(_ string: String) -> Bool {
        guard string.count >= Constants.minimumAPIKeyLength else { return false }

        let allowedSet = CharacterSet.alphanumerics.union(Constants.allowedSetCharacterSet)
        let stringSet = CharacterSet(charactersIn: string)

        return stringSet.isSubset(of: allowedSet)
    }
}

private extension HostSanitizerUtil {
    enum Constants {
        static let minimumAPIKeyLength = 20
        static let allowedSetCharacterSet: CharacterSet = .init(charactersIn: "-_")
        static let replacementCharacter: String = "_"
        static let maskAPIKeyCharacter: String = "***"
    }
}

//
//  TangemTrustEvaluatorLogger.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import TangemLogger

let TangemTrustEvaluatorLogger = Logger(category: OSLogCategory(name: "TrustEvaluator"))

enum TLSDetailsLogHelper {
    static func logTrustDetails(trust: SecTrust, forHost: String) {
        var log = "🔐 Host: \(forHost)"

        let certCount = SecTrustGetCertificateCount(trust)
        log += "\n--- Certificate Chain (\(certCount)) ---\n"

        for i in 0 ..< certCount {
            if let cert = SecTrustGetCertificateAtIndex(trust, i) {
                let subject = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown Subject"
                if let data = SecCertificateCopyData(cert) as Data? {
                    let base64 = data.base64EncodedString(options: [.lineLength64Characters])
                    log += """
                    [Certificate \(i + 1)]
                    Subject: \(subject)
                    Base64:
                    \(base64.prefix(80))... [truncated]

                    """
                }
            }
        }

        // MARK: - Trust Copy Result

        if let trustResult = SecTrustCopyResult(trust) {
            log += "\nTrustResult:\n\(trustResult)"
        } else {
            log += "\n❗️ Failed to copy trust result or convert to dictionary."
        }

        TangemTrustEvaluatorLogger.info(log)
    }
}

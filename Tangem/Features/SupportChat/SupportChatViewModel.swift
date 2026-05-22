//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SupportChatViewModel: ObservableObject, Identifiable {
    let widgetHTML: String

    /// Emits a JS snippet that injects the log zip into the widget's file input.
    let injectJSPublisher = PassthroughSubject<String, Never>()

    @Published private(set) var isSendingLogs = false

    private let logsComposer: LogsComposer

    init(input: SupportChatInputModel) {
        logsComposer = input.logsComposer
        widgetHTML = Self.makeWidgetHTML()
    }

    func sendLogs() {
        guard !isSendingLogs else { return }
        isSendingLogs = true

        logsComposer.getZipLogsData { [weak self] result in
            guard let self else { return }

            defer { DispatchQueue.main.async { self.isSendingLogs = false } }

            guard let result else { return }

            let base64 = result.data.base64EncodedString()
            let fileName = result.file.lastPathComponent

            // Build the injection script on a background thread (base64 can be large),
            // then publish on main so the view can call evaluateJavaScript.
            let script = Self.makeInjectScript(base64: base64, fileName: fileName)
            DispatchQueue.main.async { self.injectJSPublisher.send(script) }
        }
    }

    // MARK: - Private

    private static func makeInjectScript(base64: String, fileName: String) -> String {
        """
        (function() {
          try {
            var b64 = '\(base64)';
            var name = '\(fileName)';
            var bin = atob(b64);
            var buf = new Uint8Array(bin.length);
            for (var i = 0; i < bin.length; i++) { buf[i] = bin.charCodeAt(i); }
            var blob = new Blob([buf], { type: 'application/zip' });
            var file = new File([blob], name, { type: 'application/zip' });
            var input = document.querySelector('input[type="file"]');
            if (!input) { return 'NO_INPUT'; }
            var dt = new DataTransfer();
            dt.items.add(file);
            input.files = dt.files;
            input.dispatchEvent(new Event('change', { bubbles: true }));
            return 'OK';
          } catch(e) { return 'ERROR:' + e.message; }
        })();
        """
    }

    private static func makeWidgetHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { height: 100%; background: #ffffff; }

            /* Pin frame to top of sheet and fill it completely */
            .uw__messenger-layout__frame {
              top: 0 !important;
              left: 0 !important;
              right: 0 !important;
              bottom: 0 !important;
              width: 100% !important;
              height: 100% !important;
              max-height: 100% !important;
              border-radius: 0 !important;
            }

            /* Hide widget header — native drag indicator is used instead */
            .uw__widget-layout__header {
              display: none !important;
            }

            /* Hide floating trigger button */
            .uw__messenger-layout__buttons {
              display: none !important;
            }

            /* Reserve space for home indicator / safe area */
            .uw__chat-form {
              padding-bottom: var(--safe-bottom, 0px) !important;
            }

          </style>
        </head>
        <body>
          <script>
            window.usedeskSettings = { company_id: "2_54" };

            function initChat() {
              if (!window.usedeskMessenger) { return; }
              usedeskMessenger.openChat();
            }

            // Force layout recalculation after sheet animation settles
            window.addEventListener('load', function() {
              setTimeout(function() {
                window.dispatchEvent(new Event('resize'));
              }, 600);
            });

            // Primary trigger
            document.addEventListener('usedeskReady', initChat);

            // Fallback: poll until messenger is ready
            var pollInterval = setInterval(function() {
              if (window.usedeskMessenger && typeof usedeskMessenger.openChat === 'function') {
                clearInterval(pollInterval);
                initChat();
              }
            }, 200);
          </script>
          <script src="https://ud-public-widget-bucket.s3.eu-central-1.amazonaws.com//widget_2_54.js" async></script>
        </body>
        </html>
        """
    }
}

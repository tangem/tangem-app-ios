//
//  SupportChatHTMLBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Builds the inline HTML/JS for the Usedesk widget loaded into the support chat web view.
enum SupportChatHTMLBuilder {
    /// JS snippet that injects the log zip into the widget's file input.
    static func makeInjectScript(base64: String, fileName: String) -> String {
        let base64Literal = jsLiteral(base64)
        let fileNameLiteral = jsLiteral(fileName)
        return """
        (function() {
          try {
            var b64 = \(base64Literal);
            var name = \(fileNameLiteral);
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

    static func makeWidgetHTML(
        userIdentifier: String?,
        savedToken: String?,
        initialMessage: SupportInitialMessage?
    ) -> String {
        // userIdentify (not identify) matches an existing Usedesk client by a stable
        // email/name, so re-opening resumes the same chat instead of creating a new one.
        // The wallet id is used as a stable identifier (raw hex, no email format needed).
        // When we have a previously stored chat token, pass it too so Usedesk resumes
        // exactly the same client/chat; otherwise omit it and store it on this session.
        let tokenPart = savedToken.map { ", token: \(jsLiteral($0))" } ?? ""

        // Flow-specific source field (e.g. swap -> "swap").
        let additionalFieldsPart = initialMessage?.additionalFieldValue.map {
            ", additional_fields: [{ id: \(SupportInitialMessage.swapAdditionalFieldId), value: \(jsLiteral($0)) }]"
        } ?? ""

        let identifyScript = userIdentifier.map { identifier in
            let literal = jsLiteral(identifier)
            return "usedeskMessenger.userIdentify({ name: \(literal), email: \(literal)\(tokenPart)\(additionalFieldsPart) });"
        } ?? ""

        // Optional text auto-sent once the chat is ready. sendMessage needs the same
        // identity payload (name/email/token) as userIdentify.
        let initialMessageLiteral = jsLiteral(initialMessage?.message)
        let nameLiteral = jsLiteral(userIdentifier ?? "")
        let sendTokenLiteral = jsLiteral(savedToken)
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
              overflow: hidden !important;
            }

            /* Force the inner container chain down to the viewport height.
               The widget renders these with a fixed ~465px height that overflows
               the frame on short sheet detents, clipping the input bar. */
            .uw__messenger-layout__frame > div,
            .uw__frame.uw__widget-layout,
            .uw__widget-layout__content,
            .uw__chat {
              height: 100% !important;
              max-height: 100% !important;
            }

            /* Chat becomes a column: messages scroll, input pins to the bottom */
            .uw__chat {
              display: flex !important;
              flex-direction: column !important;
            }

            .uw__widget-layout__content {
              overflow-y: auto !important;
            }

            /* Hide widget header — native drag indicator is used instead */
            .uw__widget-layout__header {
              display: none !important;
            }

            /* Hide floating trigger button */
            .uw__messenger-layout__buttons {
              display: none !important;
            }

          </style>
        </head>
        <body>
          <script>
            // Mute incoming-message notification sounds. Overriding play() only on
            // HTMLAudioElement keeps video attachments playable (they use HTMLVideoElement).
            try {
              HTMLAudioElement.prototype.play = function() { return Promise.resolve(); };
            } catch (e) {}

            // Keep the latest message visible when the keyboard opens / viewport resizes:
            // the messages container doesn't auto-scroll on its own in this layout.
            // Scroll every scrollable container to the bottom (we don't know the exact one),
            // retried a few times to catch the moment after the layout settles.
            function scrollChatToBottom() {
              document.querySelectorAll('*').forEach(function(el) {
                if (el.scrollHeight > el.clientHeight + 5) {
                  el.scrollTop = el.scrollHeight;
                }
              });
            }
            function scrollChatToBottomRetrying() {
              [0, 150, 350, 600].forEach(function(delay) {
                setTimeout(scrollChatToBottom, delay);
              });
            }
            document.addEventListener('focusin', function(e) {
              if (e.target && e.target.tagName === 'TEXTAREA') {
                scrollChatToBottomRetrying();
              }
            });
            if (window.visualViewport) {
              window.visualViewport.addEventListener('resize', scrollChatToBottomRetrying);
            }

            window.usedeskSettings = { company_id: "2_54" };

            var initialMessage = \(initialMessageLiteral);

            function initChat() {
              if (!window.usedeskMessenger) { return; }

              // The widget only accepts sendMessage after a page reload following userIdentify
              // (it ignores it within the same just-identified session). So when there's an
              // initial message we identify, reload once, and send after the reload.
              if (localStorage.getItem('ud_pending_message_reload')) {
                usedeskMessenger.openChat();
                return;
              }

              try { \(identifyScript) } catch (e) {}

              if (initialMessage) {
                localStorage.setItem('ud_pending_message_reload', '1');
                try { window.webkit.messageHandlers.reloadForMessage.postMessage('reload'); } catch (e) {}
                return;
              }

              usedeskMessenger.openChat();
            }

            // Signal native side once the chat is actually rendered, so the loader hides.
            // Only fires on real readiness — the native side handles reload/timeout.
            var readyAttempts = 0;
            var readyTimer = setInterval(function() {
              readyAttempts++;
              var ready = document.querySelector('.uw__chat') || document.querySelector('textarea');
              if (ready) {
                clearInterval(readyTimer);
                try { window.webkit.messageHandlers.chatReady.postMessage('ready'); } catch (e) {}
                // Persist the current chat token (usedesk_messenger_token.data) so the next
                // open can pass it to userIdentify and resume the same client/chat.
                try {
                  var raw = localStorage.getItem('usedesk_messenger_token');
                  var token = raw ? JSON.parse(raw).data : null;
                  if (token) { window.webkit.messageHandlers.saveToken.postMessage(token); }
                } catch (e) {}
                // Auto-send the flow's initial message after the post-identify reload.
                if (initialMessage && localStorage.getItem('ud_pending_message_reload')) {
                  setTimeout(function() {
                    try {
                      usedeskMessenger.sendMessage({
                        message: initialMessage,
                        name: \(nameLiteral),
                        email: \(nameLiteral),
                        token: \(sendTokenLiteral)
                      });
                    } catch (e) {}
                    localStorage.removeItem('ud_pending_message_reload');
                  }, 1000);
                }
              } else if (readyAttempts > 60) {
                // Stop polling after ~12s; native reload will reload the page if needed.
                clearInterval(readyTimer);
              }
            }, 200);

            // Restrict file input to photos, videos, and zip archives.
            // MutationObserver catches the moment the widget inserts input[type=file] into DOM.
            var fileInputObserver = new MutationObserver(function() {
              var input = document.querySelector('input[type="file"]');
              if (input && !input.dataset.acceptPatched) {
                input.setAttribute('accept', [
                  '.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic',
                  '.mp4', '.mov', '.webm',
                  '.zip',
                  'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic',
                  'video/mp4', 'video/quicktime', 'video/webm',
                  'application/zip', 'application/x-zip-compressed'
                ].join(','));
                input.dataset.acceptPatched = '1';
              }
            });
            fileInputObserver.observe(document.body, { childList: true, subtree: true });

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

    /// Encodes a Swift string as a safe JS string literal (quoted + escaped), or `null`.
    private static func jsLiteral(_ value: String?) -> String {
        value
            .flatMap { try? JSONEncoder().encode($0) }
            .flatMap { String(data: $0, encoding: .utf8) }
            ?? "null"
    }
}

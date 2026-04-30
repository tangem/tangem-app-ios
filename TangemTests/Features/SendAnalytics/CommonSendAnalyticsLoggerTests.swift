//
//  CommonSendAnalyticsLoggerTests.swift
//  TangemTests
//
//  Created for CommonSendAnalyticsLogger unit tests.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CommonSendAnalyticsLogger")
struct CommonSendAnalyticsLoggerTests {
    // MARK: - logSendBaseViewOpened

    @Test("Send Screen Opened fires for sendType == .send")
    func sendBaseViewOpened_firesForSend() {
        let (sut, spy) = makeSUT(sendType: .send)

        sut.logSendBaseViewOpened()

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.event == .sendScreenOpened)
    }

    @Test("Send Screen Opened does NOT fire for sendType == .sell")
    func sendBaseViewOpened_doesNotFireForSell() {
        let (sut, spy) = makeSUT(sendType: .sell)

        sut.logSendBaseViewOpened()

        #expect(spy.calls.isEmpty)
    }

    @Test("Send Screen Opened does NOT fire for sendType == .nft")
    func sendBaseViewOpened_doesNotFireForNFT() {
        let (sut, spy) = makeSUT(sendType: .nft)

        sut.logSendBaseViewOpened()

        #expect(spy.calls.isEmpty)
    }

    // MARK: - logQRScannerOpened

    @Test("Button - QR Code fires with no params")
    func qrScannerOpened_firesQRCodeEvent() {
        let (sut, spy) = makeSUT()

        sut.logQRScannerOpened()

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.event == .sendButtonQRCode)
        #expect(spy.calls.first?.params.isEmpty == true)
    }

    // MARK: - logShareButton / logExploreButton

    @Test("Button - Share fires with no params")
    func shareButton_firesShareEvent() {
        let (sut, spy) = makeSUT()

        sut.logShareButton()

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.event == .sendButtonShare)
    }

    @Test("Button - Explore fires with no params")
    func exploreButton_firesExploreEvent() {
        let (sut, spy) = makeSUT()

        sut.logExploreButton()

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.event == .sendButtonExplore)
    }

    // MARK: - logDestinationStepReopened

    @Test("Address screen reopen fires Screen Reopened with method=address")
    func destinationStepReopened_firesScreenReopened() {
        let (sut, spy) = makeSUT()

        sut.logDestinationStepReopened()

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.event == .sendScreenReopened)
        #expect(spy.calls.first?.params[.method] == Analytics.ParameterValue.address.rawValue)
    }
}

// MARK: - Helpers

private extension CommonSendAnalyticsLoggerTests {
    func makeSUT(
        sendType: CommonSendAnalyticsLogger.SendType = .send,
        coordinatorSource: SendCoordinator.Source = .main
    ) -> (sut: CommonSendAnalyticsLogger, spy: AnalyticsLoggingSpy) {
        let spy = AnalyticsLoggingSpy()
        let sut = CommonSendAnalyticsLogger(
            sendType: sendType,
            coordinatorSource: coordinatorSource,
            analyticsLogger: spy
        )
        return (sut, spy)
    }
}

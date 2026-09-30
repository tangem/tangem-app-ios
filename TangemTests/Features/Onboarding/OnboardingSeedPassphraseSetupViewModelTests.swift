//
//  OnboardingSeedPassphraseSetupViewModelTests.swift
//  TangemTests
//
//  Created by Dean Rie on 28.09.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Optional passphrase on wallet creation")
struct OnboardingSeedPassphraseSetupViewModelTests {
    @Test("Off by default: valid, no passphrase, nothing to derive with")
    func disabledByDefault() async throws {
        let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: false)
        try await settle()

        #expect(viewModel.isEnabled == false)
        #expect(viewModel.isValid)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.resolvedPassphrase == nil)
    }

    @Test("Enabled but empty is not valid — the button must not create a wallet with a blank second secret")
    func enabledEmptyIsInvalid() async throws {
        let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: false)
        viewModel.isEnabled = true
        try await settle()

        #expect(viewModel.isValid == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.resolvedPassphrase == nil)
    }

    @Test("Mismatch is reported only once the confirmation is at least as long as the passphrase")
    func mismatchReporting() async throws {
        let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: false)
        viewModel.isEnabled = true
        viewModel.passphrase = "correct horse"
        viewModel.confirmation = "corr"
        try await settle()

        #expect(viewModel.isValid == false)
        #expect(viewModel.errorMessage == nil, "still typing — no error yet")

        viewModel.confirmation = "correct horsE"
        try await settle()

        #expect(viewModel.isValid == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.resolvedPassphrase == nil)
    }

    @Test("Matching confirmation resolves the passphrase verbatim (case and spaces preserved)")
    func matchingConfirmationResolves() async throws {
        let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: false)
        viewModel.isEnabled = true
        viewModel.passphrase = " Correct Horse "
        viewModel.confirmation = " Correct Horse "
        try await settle()

        #expect(viewModel.isValid)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.resolvedPassphrase == " Correct Horse ")
    }

    @Test("A passphrase longer than the SDK limit is rejected with the byte-limit message")
    func tooLongIsRejected() async throws {
        let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: false)
        viewModel.isEnabled = true
        let tooLong = String(repeating: "a", count: 257)
        viewModel.passphrase = tooLong
        viewModel.confirmation = tooLong
        try await settle()

        #expect(viewModel.isValid == false)
        #expect(viewModel.errorMessage?.contains("256") == true)
        #expect(viewModel.resolvedPassphrase == nil)
    }

    @Test("Turning the option off clears the fields and makes the screen valid again")
    func disablingClearsFields() async throws {
        let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: false)
        viewModel.isEnabled = true
        viewModel.passphrase = "secret"
        viewModel.confirmation = "secre"
        try await settle()
        #expect(viewModel.isValid == false)

        viewModel.isEnabled = false
        try await settle()

        #expect(viewModel.passphrase.isEmpty)
        #expect(viewModel.confirmation.isEmpty)
        #expect(viewModel.isValid)
        #expect(viewModel.resolvedPassphrase == nil)
    }

    @Test("Card flow: the create button needs the words AND a valid passphrase state; the action receives the passphrase")
    func validationScreenGatesOnPassphrase() async throws {
        var received: String?? = nil
        let viewModel = OnboardingSeedPhraseUserValidationViewModel(
            mode: .card,
            validationInput: .init(
                secondWord: "tree",
                seventhWord: "lunar",
                eleventhWord: "banana",
                allowsPassphrase: true,
                createWalletAction: { received = .some($0) }
            )
        )
        let passphraseSetup = try #require(viewModel.passphraseSetupViewModel)

        viewModel.firstInputText = "tree"
        viewModel.secondInputText = "lunar"
        viewModel.thirdInputText = "banana"
        try await settle(milliseconds: 700) // the word inputs are debounced by 0.5 s
        #expect(viewModel.isCreateWalletButtonEnabled)

        passphraseSetup.isEnabled = true
        try await settle()
        #expect(viewModel.isCreateWalletButtonEnabled == false, "opted in but nothing typed yet")

        passphraseSetup.passphrase = "hunter2"
        passphraseSetup.confirmation = "hunter2"
        try await settle()
        #expect(viewModel.isCreateWalletButtonEnabled)

        viewModel.createWallet()
        #expect(received == .some("hunter2"))

        passphraseSetup.isEnabled = false
        try await settle()
        viewModel.createWallet()
        #expect(received == .some(nil))
    }

    @Test("Mobile validation flow does not offer the toggle")
    func mobileFlowHasNoToggle() {
        let viewModel = OnboardingSeedPhraseUserValidationViewModel(
            mode: .mobile,
            validationInput: .init(secondWord: "a", seventhWord: "b", eleventhWord: "c", createWalletAction: { _ in })
        )

        #expect(viewModel.passphraseSetupViewModel == nil)
    }

    /// The view models publish through `receive(on: DispatchQueue.main)`; let the main queue drain.
    private func settle(milliseconds: Int = 50) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
    }
}

# Dangerfile
# frozen_string_literal: true

# rubocop:disable Style/SignalException
# rubocop:disable Layout/LineLength
# rubocop:disable Layout/MultilineOperationIndentation

require 'json'
require 'open3'

# Warn if there are any big PRs
message('❗️Big PR detected. Consider breaking it down.❗️') if git.lines_of_code > 500

# PR must have a meaningful description
fail('Please provide a more detailed PR description.') if github.pr_body.length < 20

# Warn if there are any TODOs or FIXMEs left in the code
todo_fixme_found = git.modified_files.grep(/\.swift$/).any? do |file|
  File.read(file).match?(/TODO|FIXME/)
rescue StandardError => e
  puts e.message
  false
end
message('❗️There are TODOs/FIXMEs left in the code. Consider fixing them before merge.❗️') if todo_fixme_found

# Linting rules violation check
_, lint_stderr, lint_status = Open3.capture3('mint run swiftformat@0.55.5 . --config .swiftformat --lint')
fail("Linting error, fix to continue:\n#{lint_stderr}") unless lint_status.success?

# Xcode build results analyzing
errors_count = 0
warnings_count = 0
result_bundle_paths = [
  './build_results/Tangem.xcresult',
  './build_results/TangemModules.xcresult',
  './build_results/BlockchainSdkExample.xcresult',
]

# ❗️❗️❗️ DO NOT ADD new entries to this list just to silence new compiler warnings. Always consult with the team first ❗️❗️❗️
xcode_summary.ignored_results do |result|
  message = result.message
  file = result.location&.file_name || '' # May be absent if the warning isn't related to the source code, e.g. warnings in pbxproj
  message.include?('TODO: ') || # Various TODOs
  message.end_with?("LockGate' is deprecated: replace with general purpose forced-timeout function in https://tangem.atlassian.net/browse/IOS-10522") || # Normal deprecation
  message.end_with?("'windows' was deprecated in iOS 15.0: Use UIWindowScene.windows on a relevant window scene instead") || # Normal deprecation
  message.end_with?("'animation' was deprecated in iOS 15.0: Use withAnimation or animation(_:value:) instead.") || # SwiftUI
  message.end_with?("was built for newer 'iOS-simulator' version (17.5) than being linked (15.0)") || # Reown
  message.end_with?('is deprecated: use a mirror query') || # Hedera
  message.end_with?("Duplicate symbol '_ge25519_double_scalarmult_vartime' in:") || # Perhaps a false positive in the BlockchainSdkExample target
  message.end_with?("Duplicate symbol '_ge25519_add' in:") || # Perhaps a false positive in the BlockchainSdkExample target
  message.end_with?("Duplicate symbol '_ge25519_scalarmult' in:") || # Perhaps a false positive in the BlockchainSdkExample target
  message.end_with?("Sendability of function types in instance method 'urlSession(_:didReceive:completionHandler:)' does not match requirement in protocol 'URLSessionDelegate'; this is an error in the Swift 6 language mode") || # IDK how to fix this
  (message.end_with?('Switch condition evaluates to a constant') && file == 'Blockchain+AllCases.swift') || # Expected
  (message.end_with?('Switch condition evaluates to a constant') && file == 'NFTContractType.swift') || # Expected
  (message.end_with?('Switch condition evaluates to a constant') && file == 'NFTChain.swift') # Expected
end

xcode_summary.collapse_parallelized_tests = true

result_bundle_paths.each do |path|
  unless File.exist?(path)
    message("No build results at path '#{path}', skipping check")
    next
  end

  xcode_summary.report path
  xcode_summary_result = xcode_summary.warning_error_count path

  if xcode_summary_result.to_s == '["summary file not found"]'
    puts "No build results for path '#{path}'"
    next
  end

  xcode_summary_result_json = JSON.parse(xcode_summary_result)
  errors_count += xcode_summary_result_json['errors'].to_i
  warnings_count += xcode_summary_result_json['warnings'].to_i
rescue StandardError => e
  warn("Cannot analyze build results for path '#{path}' due to error '#{e.message}'")
  next
end

fail('The PR has introduced new compiler errors. Fix them to continue.') if errors_count.positive?
fail('The PR has introduced new compiler warnings. Fix them to continue.') if warnings_count.positive?

# rubocop:enable Style/SignalException
# rubocop:enable Layout/LineLength
# rubocop:enable Layout/MultilineOperationIndentation

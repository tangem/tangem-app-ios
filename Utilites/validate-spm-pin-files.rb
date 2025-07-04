#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# --- Constants ---

SUPPORTED_PIN_FILE_VERSION = 3
SUPPORTED_DEPENDENCY_KIND = 'remoteSourceControl'

# --- DTO ---

PackageState = Struct.new(:revision, :version, keyword_init: true)

PackagePin = Struct.new(:identity, :kind, :location, :state, keyword_init: true) do
  def self.from_json(json)
    new(
      identity: json['identity'],
      kind: json['kind'],
      location: json['location'],
      state: json['state'] ? PackageState.new(revision: json['state']['revision'], version: json['state']['version']) : nil
    )
  end
end

PackageFile = Struct.new(:origin_hash, :pins, :version, keyword_init: true) do
  def self.from_json(json)
    new(
      origin_hash: json['originHash'],
      pins: json['pins'].map { |pin_json| PackagePin.from_json(pin_json) },
      version: json['version']
    )
  end
end

def load_json(file_path)
  JSON.parse(File.read(file_path))
rescue Errno::ENOENT
  puts "::error::Error: File '#{file_path}' not found."
  exit(1)
rescue JSON::ParserError => e
  puts "::error::Error: Invalid JSON in '#{file_path}': #{e.message}"
  exit(1)
end

# --- Main routine ---

def compare_packages(file1_path, file2_path)
  json1 = load_json(file1_path)
  package1 = PackageFile.from_json(json1)

  json2 = load_json(file2_path)
  package2 = PackageFile.from_json(json2)

  if (package1.version != SUPPORTED_PIN_FILE_VERSION) || (package2.version != SUPPORTED_PIN_FILE_VERSION)
    puts "::error::Error: Can't compare SPM pin files of unknown version"
    exit(1)
  end

  pins2_identity_map = package2.pins.to_h { |pin| [pin.identity, pin] }
  pins2_location_map = package2.pins.to_h { |pin| [pin.location, pin] }
  mismatches = []

  package1.pins.each do |pin1|
    pin2 = pins2_identity_map[pin1.identity] || pins2_location_map[pin1.location]

    next unless !pin2.nil? && pin1.kind == SUPPORTED_DEPENDENCY_KIND && pin2.kind == SUPPORTED_DEPENDENCY_KIND && pin1.state != (pin2.state)

    pin1_info = "'#{pin1.state.version}'/'#{pin1.state.revision}'"
    pin2_info = "'#{pin2.state.version}'/'#{pin2.state.revision}'"
    mismatches << "SPM dependency '#{pin1.identity}': version mismatch between App (#{pin1_info}) and Modules (#{pin2_info})"
  end

  # Report results
  if mismatches.any?
    puts '::error::Validation failed. Mismatches found.'
    mismatches.each { |mismatch| puts "::error::#{mismatch}" }
    exit(1)
  else
    puts '::notice::Validation passed. No mismatches found.'
  end
end

# --- Main execution ---

if ARGV.length != 2
  puts "::notice::Usage: ruby #{File.basename($PROGRAM_NAME)} <file1> <file2>"
  exit(1)
end

compare_packages(ARGV[0], ARGV[1])

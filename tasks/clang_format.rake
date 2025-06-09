# frozen_string_literal: true

require "shellwords"

EXTS = %w[c cc cpp cxx h hh hpp hxx].freeze
SDK_PATH = "ext/xmp_toolkit_ruby/XMP-Toolkit-SDK/"

def clang_format_files
  Dir.glob("ext/**/*.{#{EXTS.join(",")}}")
     .select { |file| File.file?(file) && !file.start_with?(SDK_PATH) }
end

namespace :clang_format do
  desc "Format all C/C++ source and header files in ext/ with clang-format"
  task :autocorrect_all do
    clang_format_files.each do |file|
      puts "Formatting #{file}"
      system("clang-format -i #{Shellwords.escape(file)}")
    end
    puts "All files in ext/ have been formatted."
  end

  desc "Validate that all C/C++ files in ext/ are formatted with clang-format"
  task :validate do
    unformatted = []
    clang_format_files.each do |file|
      diff = `clang-format #{Shellwords.escape(file)} | diff #{Shellwords.escape(file)} -`
      unformatted << file unless diff.empty?
    end

    if unformatted.any?
      puts "The following files are NOT properly formatted:\n\n"
      unformatted.each { |f| puts "  #{f}" }
      puts "\nPlease run: rake clang_format:autocorrect_all"
      abort("clang-format validation failed.")
    else
      puts "All C/C++ files in ext/ are properly formatted."
    end
  end
end

# Optional: keep your old top-level task name for compatibility
desc "Validate that all C/C++ files in ext/ are formatted with clang-format"
task clang_format: "clang_format:validate"

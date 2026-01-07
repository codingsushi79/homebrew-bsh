# typed: strict
# frozen_string_literal: true

class Bsh < Formula
  desc "Basic Hacker Tools - Network information gathering tools"
  homepage "https://github.com/codingsushi79/bsh"
  url "https://github.com/codingsushi79/bsh.git",
      revision: "3462ed78e9f785c1fee38e2815d848b0bad97a27"
  version "1.0.0"
  license "MIT"

  def install
    # Install the main script
    bin.install "bsh.rb" => "bsh"
    
    # Fix path resolution for symlink support (File.realpath instead of File.expand_path)
    inreplace bin/"bsh", "File.expand_path(__FILE__)", "File.realpath(__FILE__)"
    
    # Install the library files to libexec (private directory)
    # The script will find them via $LOAD_PATH
    libexec.install Dir["lib"]
  end

  test do
    # Test that the binary exists and can run
    assert_path_exists bin/"bsh"
    assert_match "BSH - Basic Hacker Tools", shell_output("#{bin}/bsh help")
  end
end

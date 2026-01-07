# typed: strict
# frozen_string_literal: true

class Bsh < Formula
  desc "Basic Hacker Tools - Network information gathering tools"
  homepage "https://github.com/codingsushi79/bsh"
  url "https://github.com/codingsushi79/bsh.git",
      revision: "HEAD"
  version "1.0.0"
  license "MIT"

  def install
    # Install the main script
    bin.install "bsh.rb" => "bsh"
    
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

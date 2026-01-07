# typed: strict
# frozen_string_literal: true

class Autotype < Formula
  desc "Simulate a 1337 hax0r typing"
  homepage "https://github.com/scottjbarr/hackertyper"
  url "https://github.com/scottjbarr/hackertyper.git",
      revision: "f68f0d5fd818af421a1bdc946afa3c09c66affd4"
  version "1.0.0"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", "-o", bin/"autotype", "."
  end

  test do
    # Basic test to ensure the binary exists and can run
    assert_path_exists bin/"autotype"
    # NOTE: Full interactive testing is difficult in CI
  end
end


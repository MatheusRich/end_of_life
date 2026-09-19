class EndOfLife < Formula
  desc "List GitHub repositories using end-of-life software"
  homepage "https://github.com/MatheusRich/end_of_life"
  version "@VERSION@"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "@BASE@/end_of_life-@TAG@-macos-arm64.tar.gz"
      sha256 "@SHA_MACOS_ARM64@"
    end

    on_intel do
      url "@BASE@/end_of_life-@TAG@-macos-x86_64.tar.gz"
      sha256 "@SHA_MACOS_X86_64@"
    end
  end

  on_linux do
    on_arm do
      url "@BASE@/end_of_life-@TAG@-linux-arm64.tar.gz"
      sha256 "@SHA_LINUX_ARM64@"
    end

    on_intel do
      url "@BASE@/end_of_life-@TAG@-linux-x86_64.tar.gz"
      sha256 "@SHA_LINUX_X86_64@"
    end
  end

  def install
    odie "macOS 15 (Sequoia) or newer is required" if OS.mac? && MacOS.version < :sequoia

    bin.install "end_of_life"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/end_of_life --version")
  end
end

cask "clipboard" do
  version "0.1.1"
  sha256 "62700b9fc5590e1497275f091917213d92280d1d3f3969007be315737c278e69"

  url "https://github.com/shirangabriel/clipboard/releases/download/v#{version}/Clipboard-#{version}-macos.zip"
  name "Clipboard"
  desc "macOS menu bar clipboard utility for history, sections, and favorites"
  homepage "https://github.com/shirangabriel/clipboard"

  depends_on macos: ">= :sonoma"

  app "Clipboard.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Clipboard.app"],
                   must_succeed: false
  end

  zap trash: "~/Library/Application Support/Clipboard"
end

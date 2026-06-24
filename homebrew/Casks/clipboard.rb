cask "clipboard" do
  version "0.1.2"
  sha256 "efda1501af30c780a2509369e8874efb65c5be8bbb72e3faaac4a338f37f8bf3"

  url "https://github.com/shirangabriel/clipboard/releases/download/v#{version}/Clipboard-#{version}-macos.zip"
  name "Clipboard"
  desc "macOS menu bar clipboard utility for history, sections, and favorites"
  homepage "https://github.com/shirangabriel/clipboard"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "Clipboard.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Clipboard.app"],
                   must_succeed: false
  end

  zap trash: "~/Library/Application Support/Clipboard"
end

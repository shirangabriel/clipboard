cask "clipboard" do
  version "0.1.0"
  sha256 "1034be2c328969319ee2b95f53185789f4f42a2a1feeeff103e621deccfc2caa"

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

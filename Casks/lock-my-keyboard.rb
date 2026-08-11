cask "lock-my-keyboard" do
  version "1.0.0"
  sha256 "054d16e0227aa85c2b7f1df5f41fe521c1dc95c06f31fb460f86d7512a04a186"

  url "https://github.com/mahboobmonnamd/lock-my-keyboard/releases/download/v#{version}/LockMyKeyboard-#{version}.zip"
  name "Lock My Keyboard"
  desc "Temporarily disable the keyboard so you can clean it safely"
  homepage "https://github.com/mahboobmonnamd/lock-my-keyboard"

  depends_on arch: :arm64
  depends_on macos: ">= :tahoe"

  app "LockMyKeyboard.app"

  # Unsigned first release: clear Gatekeeper quarantine after install.
  postflight do
    app_path = "#{appdir}/LockMyKeyboard.app"
    system_command "/usr/bin/xattr", args: ["-cr", app_path], sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.lockmykeyboard.app.plist",
    "~/Library/Application Support/Lock My Keyboard",
  ]
end

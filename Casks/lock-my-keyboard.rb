cask "lock-my-keyboard" do
  version "1.0.1"
  sha256 "d8c60775f91bda7c2c5ab8f10c1fd77ee503b82a4c469c8a27015f2f7b141d83"

  url "https://github.com/mahboobmonnamd/lock-my-keyboard/releases/download/v#{version}/LockMyKeyboard-#{version}.zip"
  name "Lock My Keyboard"
  desc "Temporarily disable the keyboard so you can clean it safely"
  homepage "https://github.com/mahboobmonnamd/lock-my-keyboard"

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "LockMyKeyboard.app"

  # Unsigned distribution: removes quarantine and bypasses Gatekeeper origin checks.
  # Remove when Developer ID notarization becomes available; see docs/INSTALL.md.
  postflight do
    app_path = "#{appdir}/LockMyKeyboard.app"
    system_command "/usr/bin/xattr", args: ["-cr", app_path], sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.lockmykeyboard.app.plist",
    "~/Library/Application Support/Lock My Keyboard",
  ]
end

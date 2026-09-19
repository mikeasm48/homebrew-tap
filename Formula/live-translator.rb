class LiveTranslator < Formula
  desc "Live speech translation (Uzbek/Russian/English) via Yandex AI Studio"
  homepage "https://github.com/mikeasm48/live_translator"
  url "https://github.com/mikeasm48/live_translator/releases/download/v0.2.1/live-translator-0.2.1.jar",
      using: :nounzip
  sha256 "4ed37027a707aac8020c57afdced4b08069ca5d31058a0f36d547caef398829b"
  version "0.2.1"

  depends_on "openjdk@21"

  def install
    libexec.install "live-translator-0.2.1.jar" => "live-translator.jar"

    # Обёртка вызывает Java из зависимости формулы, поэтому системная версия
    # Java ни на что не влияет и ставить её отдельно не нужно.
    (bin/"live-translator").write <<~SCRIPT
      #!/bin/bash
      exec "#{Formula["openjdk@21"].opt_bin}/java" -jar "#{opt_libexec}/live-translator.jar" "\"
    SCRIPT

    build_app
  end

  # Полноценный .app, чтобы приложение запускалось из «Программ», а не только
  # из терминала. Внутри — лишь иконка и запускающий скрипт: сам jar остаётся
  # в Cellar, поэтому копия в «Программах» весит килобайты.
  def build_app
    app = prefix/"Live Translator.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath

    system "unzip", "-o", "-j", libexec/"live-translator.jar", "live-translator.icns",
           "-d", app/"Contents/Resources"

    (app/"Contents/Info.plist").write <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key><string>Live Translator</string>
        <key>CFBundleDisplayName</key><string>Live Translator</string>
        <key>CFBundleIdentifier</key><string>com.mikeasm.livetranslator</string>
        <key>CFBundleExecutable</key><string>live-translator</string>
        <key>CFBundleIconFile</key><string>live-translator</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>CFBundleVersion</key><string>#{version}</string>
        <key>LSMinimumSystemVersion</key><string>12.0</string>
        <key>NSHighResolutionCapable</key><true/>
        <key>NSMicrophoneUsageDescription</key>
        <string>Приложение слушает микрофон или виртуальный аудиокабель, чтобы переводить речь.</string>
      </dict>
      </plist>
    PLIST

    launcher = app/"Contents/MacOS/live-translator"
    launcher.write <<~SCRIPT
      #!/bin/bash
      # Запуск из Finder: имя и иконка в Dock задаются явно, иначе система
      # покажет процесс как «java».
      exec "#{Formula["openjdk@21"].opt_bin}/java" \\
        -Xdock:name="Live Translator" \\
        -Xdock:icon="#{opt_prefix}/Live Translator.app/Contents/Resources/live-translator.icns" \\
        -Dapple.awt.application.name="Live Translator" \\
        -jar "#{opt_libexec}/live-translator.jar" "\"
    SCRIPT
    launcher.chmod 0755
  end

  def post_install
    # Копия в «Программах» — это лишь оболочка с иконкой и скриптом, поэтому
    # дублирования jar не происходит. Симлинк здесь хуже: Launchpad и Spotlight
    # показывают такие приложения ненадёжно.
    target = Pathname.new("/Applications/Live Translator.app")
    rm_rf target
    cp_r opt_prefix/"Live Translator.app", target
  rescue => e
    opoo "Не удалось поместить приложение в «Программы»: #{e.message}"
  end

  def caveats
    <<~TEXT
      Live Translator добавлен в «Программы» — запускается двойным щелчком.
      Из терминала тоже работает: live-translator

      Настройки и словарь терминов: ~/.config/live-translator/
      Расшифровки встреч и записи звука: ~/Documents/LiveTranslator/

      При первом запуске приложение спросит каталог Yandex Cloud и API-ключ.
      Ключ сохраняется в связке ключей macOS.

      Для звука из созвонов нужен BlackHole:
        brew install blackhole-2ch
      Пошаговая настройка — в приложении: Cmd + , → «Звук из созвона».

      При удалении копия в «Программах» не убирается автоматически:
        rm -rf "/Applications/Live Translator.app"
    TEXT
  end

  test do
    assert_match "Live Translator", shell_output("#{bin}/live-translator --help")
  end
end

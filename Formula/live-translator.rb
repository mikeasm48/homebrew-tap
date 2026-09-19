class LiveTranslator < Formula
  desc "Live speech translation (Uzbek/Russian/English) via Yandex AI Studio"
  homepage "https://github.com/mikeasm48/live_translator"
  url "https://github.com/mikeasm48/live_translator/releases/download/v0.1.0/live-translator-0.1.0.jar",
      using: :nounzip
  sha256 "c83505c2058ee69bc10770cb9f26c50ecc2feda0ca8f6686fb7299c383a3c6da"
  version "0.1.0"

  depends_on "openjdk@21"

  def install
    libexec.install "live-translator-0.1.0.jar" => "live-translator.jar"

    # Обёртка вызывает Java из зависимости формулы, поэтому отдельно ставить
    # её не нужно — и системная версия Java ни на что не влияет.
    (bin/"live-translator").write <<~SCRIPT
      #!/bin/bash
      exec "#{Formula["openjdk@21"].opt_bin}/java" -jar "#{libexec}/live-translator.jar" "$@"
    SCRIPT
  end

  def caveats
    <<~TEXT
      Настройки и словарь терминов: ~/.config/live-translator/
      Расшифровки встреч и записи звука: ~/Documents/LiveTranslator/

      При первом запуске приложение спросит каталог Yandex Cloud и API-ключ.
      Ключ сохраняется в связке ключей macOS.

      Для звука из созвонов нужен BlackHole:
        brew install blackhole-2ch
      Пошаговая настройка — в приложении: Cmd + , → «Звук из созвона».
    TEXT
  end

  test do
    assert_match "Live Translator", shell_output("#{bin}/live-translator --help")
  end
end

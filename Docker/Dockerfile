# OpenJDKの公式イメージをベースとして使用
FROM openjdk:17-jdk-slim

# コンテナ内の作業ディレクトリを設定
WORKDIR /app

# Processingのコアライブラリ (core.jar) をホストマシンからコンテナ内にコピー
# このファイルは、Processingのインストールディレクトリから入手する必要があります
COPY core.jar /app/core.jar

# 実行したいProcessingスケッチのJARファイルをホストマシンからコンテナ内にコピー
# (例: スケッチをエクスポートして作成した my_sketch.jar)
COPY Dangeons.jar /app/Dangeons.jar

# コンテナ起動時にスケッチを実行するコマンド
# スケッチのメインクラス名に合わせて "YourMainClass" の部分を変更してください
CMD ["java", "-cp", "core.jar:Dangeons.jar", "Dangeons"]

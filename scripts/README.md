# Icon Generation Scripts

このディレクトリには、MIDIRealtimeToCCアプリのアイコンを生成するスクリプトが含まれています。

## スクリプト一覧

### generate_app_icon.swift
アプリケーションアイコン（AppIcon）を生成します。
- 16x16から1024x1024まで、全10サイズのアイコンを生成
- MIDIコネクタ → 矢印 → CC のデザイン
- 青いグラデーション背景

### generate_menubar_icon.swift
メニューバーアイコン（MenuBarIcon）を生成します。
- 18pt、36pt (2x)、54pt (3x) の3サイズを生成
- テンプレートイメージ（ライト/ダークモード自動対応）
- アプリアイコンと同じデザインをシンプル化

## 使用方法

プロジェクトルートから実行してください：

```bash
# アプリアイコンを生成
./scripts/generate_app_icon.swift

# メニューバーアイコンを生成
./scripts/generate_menubar_icon.swift
```

## 出力先

生成されたアイコンは以下のディレクトリに保存されます：

- アプリアイコン: `MIDIRealtimeToCC/MIDIRealtimeToCCApp/Assets.xcassets/AppIcon.appiconset/`
- メニューバーアイコン: `MIDIRealtimeToCC/MIDIRealtimeToCCApp/Assets.xcassets/MenuBarIcon.imageset/`

## 要件

- macOS
- Swift (Xcode Command Line Tools)

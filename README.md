# lesson2-lib

演習で使う講師作成のクラス群。学生の Codespace から `bin/update` で取得される。

## 構成

```
lib/
├── lesson.rb          まとめ読み込み（学生はこれを require する）
├── lesson/
│   └── version.rb     バージョン文字列
└── greeter.rb         クラス本体を1ファイル1クラスで置く
```

## クラスを追加する手順

1. `lib/dice.rb` のようにファイルを追加する
2. `lib/lesson.rb` に `require_relative 'dice'` を1行足す
3. `lib/lesson/version.rb` の `VERSION` を更新する
4. commit して push

学生が `bin/update` を実行すれば即座に反映される。

## 注意

- **既存メソッドの削除・引数変更は演習期間中に行わない。** 1日目の課題を見直している学生のコードが壊れる。追加は安全、変更は危険。
- ファイル名は学生が書くファイルと衝突しない名前にする（`utils.rb` `helper.rb` などは避ける）。
- public リポジトリなので、課題の解答は置かないこと。

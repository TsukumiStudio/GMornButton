# GMornButton

## 概要

指乗せ・押下・押せないの反応と、押下時の決定音を釦の土台にまとめるGodotアドオン。

釦に要るものはどの作品でもだいたい同じである。指を乗せたら色が変わる、押したら音が鳴る、押せないときは沈む。これを釦ごとに書くと必ずどこか一つだけ抜ける。抜けた場所は「なんとなく反応が薄い」としか気付けない。

## 動作環境

- Godot 4.x（4.7で確認）
- [GMornBeat](https://github.com/TsukumiStudio/GMornBeat)（拍で拍動させたいときだけ。無くても動く）

## 何ができるか

- **4つの状態で色が変わる**。通常・指乗せ/焦点・押下・押せない。焦点でも変わるので、鍵盤や手元機で選んでいるときもどこを選んでいるか分かる。
- **色は作品ごとに1か所**。`ProjectSettings` から取る。釦ごとに持たせると、後から色を変えるときに置いてある釦を全部開いて直すことになる。
- **音の相手を指し示さない**。組（group）から探す。釦を置くたびに繋ぎ直す必要がなく、音を持たない場面でもそのまま置ける。
- **拍動の部品が無くても壊れない**。`GMornBeat` は実行時に読む。`preload` で指すと、その部品を取っていない状態では台本ごと読めなくなる。釦は画面のどこにでもあるので、そうなると何も押せない。実際に、書き出しの手順が submodule を取っておらず、配ったものだけ釦が軒並み壊れていた。

## 使い方

### 1. 取り込む

アドオン一式をリポジトリ直下へ置いてある。取り込む側の `addons/gmorn_button` へそのまま submodule として足せる。

```
git submodule add https://github.com/TsukumiStudio/GMornButton.git addons/gmorn_button
```

Godotのエディタで「プロジェクト設定 → プラグイン」から `GMornButton` を有効にする。「ノードを追加」に `GMornButton` が出るようになる。

**リポジトリ直下に `project.godot` は置かない。** 置くとGodotがそこを別のプロジェクトと見なし、**そのフォルダを丸ごとスキャンから外す**。submoduleとして取り込んだ場合、エディタでは動くのに書き出した実行ファイルにだけアドオンが入らない。

### 2. 土台の `.tscn` を1つ作る

釦の見た目は作品ごとに何種類かある。土台を1つ作って、そこから継承したほうが後で楽になる。

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/gmorn_button/gmorn_button.gd" id="1_script"]

[node name="MyButton" type="TextureButton"]
action_mode = 0
script = ExtResource("1_script")
```

`type` は `BaseButton` を継ぐものなら何でもよい（`TextureButton` / `Button` / `TouchScreenButton` 以外の派生）。

### 3. 色を決める

`project.godot` に足す。

```
[gmorn_button]

highlighted_color=Color(0.99, 0.25, 0.91, 1)
pressed_color=Color(0.99, 0.25, 0.91, 1)
disabled_color=Color(0.65, 0.65, 0.65, 1)
disabled_highlighted_color=Color(0.8, 0.27, 0.74, 1)
```

`"#ff00ff"` のような文字でも受ける。手で書くときはそちらのほうが書きやすい。

| 項目 | プロジェクト設定 | 既定 |
| --- | --- | --- |
| 通常 | `gmorn_button/normal_color` | 白 |
| 指乗せ・焦点 | `gmorn_button/highlighted_color` | `Color(0.8, 0.8, 0.8)` |
| 押下 | `gmorn_button/pressed_color` | `Color(0.65, 0.65, 0.65)` |
| 押せない | `gmorn_button/disabled_color` | `Color(0.65, 0.65, 0.65)` |
| 押せない＋指乗せ | `gmorn_button/disabled_highlighted_color` | `Color(0.5, 0.5, 0.5)` |
| 決定音の組 | `gmorn_button/submit_audio_group` | `morn_ui_submit_audio` |

### 4. 決定音を鳴らす

鳴らす `AudioStreamPlayer` を組に入れる。釦側の設定は要らない。

```
[node name="SubmitSe" type="AudioStreamPlayer" parent="."]
stream = ExtResource("submit_se")
groups = ["morn_ui_submit_audio"]
```

### 5. 釦ごとに変える

| 項目 | 何を決めるか | 既定 |
| --- | --- | --- |
| `background_style` | 背景の描き方。`null` なら見えない釦 | `null` |
| `play_submit_sound` | 押下で鳴らすか | `true` |
| `beat_scale_enabled` | 拍で拍動するか | `false` |

拍動の既定を無効にしてあるのは、画面のすべてが揺れるとどれが押せるのか分からなくなるためである。揺らしたい釦にだけ付ける。

### その他の口

| 呼び出し | 何をするか |
| --- | --- |
| `pulse()` | 1拍ぶん拍動する。拍を配る側から呼ばれる |
| `GMornButton.settings()` | いま効いている設定 |
| `GMornButton.reload_settings()` | 設定を読み直させる。色を実行中に変えたときに使う |
| `GMornButton.set_focus_tint_enabled(bool)` | 焦点の色を出すかどうかを、画面のすべての釦へ一度に効かせる（既定は出す） |

焦点の色は、手元機や鍵盤で選んでいる人には要る。一方で、起動した時点で最初の釦へ焦点を置く作りだと、**誰も触っていないのに1つだけ色が付いている**画面になる。マウスで遊ぶ人には、押してもいない釦が選ばれているように見える。

作品の側で「最後に触ったのが手元機か鍵盤なら出す、マウスなら出さない」と決められる。指を乗せたときの色は、この切り替えとは無関係に出る。塗り直しは各釦の毎こまの更新が拾うので、値を置くだけでよい。

### 手を入れる

`verify.sh` で、状態ごとの色と音の探し方が通ることを確かめられる。一時の置き場へ最小のプロジェクトを作り、この部品を写して回す。

```
./verify.sh
```

## ライセンス

Unlicense（パブリックドメイン）。

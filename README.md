# GMornButton

## 概要

指乗せ・押下・押せないの反応と、押下時の決定音を釦の土台にまとめるGodotアドオン。

指を乗せたら色が変わる、押したら音が鳴る、押せないときは沈む、を釦ごとに書くとどこか一つが抜ける。土台に集めて抜けをなくす。

## 動作環境

- Godot 4.x（4.7で確認）
- [GMornBeat](https://github.com/TsukumiStudio/GMornBeat)（拍で拍動させたいときだけ。無くても動く）

## 何ができるか

- **4つの状態で色が変わる**。通常・指乗せ/焦点・押下・押せない。焦点でも変わるので、鍵盤や手元機で選んでいるときもどこを選んでいるか分かる。
- **色は色の組（`.tres`）で決める**。作品の既定の組を1つ決め、違う色が要る釦だけ別の組を指す。
- **音の相手を指し示さない**。組（group）から探すので、音を持たない場面でもそのまま置ける。
- **拍動の部品が無くても壊れない**。`GMornBeat` は実行時に読む。無ければ拍動しないだけ。

## 使い方

### 1. 取り込む

アドオン一式をリポジトリ直下へ置いてある。取り込む側の `addons/gmorn_button` へそのまま submodule として足せる。

```
git submodule add https://github.com/TsukumiStudio/GMornButton.git addons/gmorn_button
```

Godotのエディタで「プロジェクト設定 → プラグイン」から `GMornButton` を有効にする。「ノードを追加」に `GMornButton` が出るようになる。

**リポジトリ直下に `project.godot` は置かない。** 置くとGodotがそこを別のプロジェクトと見なし、submoduleとして取り込んだ側の書き出しからフォルダごと外れる。

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

色の組を `.tres` で作る（ファイルシステムで右クリック →「新規リソース」→ `Resource` を選び、台本に `gmorn_button_colors.gd` を指す）。

| 項目 | 何の色か | 既定 |
| --- | --- | --- |
| `normal_color` | 焦点が無く、押せる | 白 |
| `focused_color` | 焦点がある・指が乗っている・押している | 白 |
| `disabled_tint` | 押せないときに上の2色へ掛ける差分 | `Color(0.65, 0.65, 0.65)` |

押せないときは色を置き換えず、差分を掛ける。押せない釦にもパッドの焦点は来るので、置き換えると焦点の有無が見えなくなる。押下を別の色にする項目は持たない。組を作るたびに埋める欄が増えるわりに、焦点と押下で色を分けたい釦がまだ無い。

作品の既定の組を `project.godot` に書く。釦はふつう何も指さず、これを使う。

```
[gmorn_button]

default_colors="res://ui/button_colors/standard.tres"
```

違う色が要る釦だけ、釦の `colors` に別の組を指す。組を増やすのは意味が違うときだけにする。色の微調整ごとに組を作ると、作品の色を変えるときに組を全部開いて直すことになる。焦点で色を変えたくない釦（子の文字に色が乗ると困る見えない釦など）は、`focused_color` を `normal_color` と同じにした組を指す。

`default_colors` を書いていない作品は、以前の5色の設定をそのまま使う。

| 項目 | プロジェクト設定 | 既定 |
| --- | --- | --- |
| 既定の組 | `gmorn_button/default_colors` | なし |
| 通常（組なし） | `gmorn_button/normal_color` | 白 |
| 指乗せ・焦点（組なし） | `gmorn_button/highlighted_color` | `Color(0.8, 0.8, 0.8)` |
| 押下（組なし） | `gmorn_button/pressed_color` | `Color(0.65, 0.65, 0.65)` |
| 押せない（組なし） | `gmorn_button/disabled_color` | `Color(0.65, 0.65, 0.65)` |
| 押せない＋指乗せ（組なし） | `gmorn_button/disabled_highlighted_color` | `Color(0.5, 0.5, 0.5)` |
| 決定音の組 | `gmorn_button/submit_audio_group` | `morn_ui_submit_audio` |

5色は `"#ff00ff"` のような文字でも受ける。

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
| `colors` | 色の組。`null` なら作品の既定の組 | `null` |
| `background_style` | 背景の描き方。`null` なら見えない釦 | `null` |
| `play_submit_sound` | 押下で鳴らすか | `true` |
| `beat_scale_enabled` | 拍で拍動するか | `false` |

拍動は既定で無効。画面のすべてが揺れるとどれが押せるのか分からなくなるので、揺らしたい釦にだけ付ける。

### その他の口

| 呼び出し | 何をするか |
| --- | --- |
| `pulse()` | 1拍ぶん拍動する。拍を配る側から呼ばれる |
| `GMornButton.settings()` | いま効いている設定 |
| `GMornButton.reload_settings()` | 設定を読み直させる。色を実行中に変えたときに使う |
| `GMornButton.tint_color(colors, highlighted, pressed, disabled)` | 組（`null` なら既定）から状態の色を引く。`BaseButton` を継げない自前の部品にも釦と同じ色を出させるときに使う |
| `GMornButton.set_focus_tint_enabled(bool)` | 焦点の色を出すかどうかを、画面のすべての釦へ一度に効かせる（既定は出す） |

焦点の色は手元機や鍵盤で選ぶ人には要るが、起動時に最初の釦へ焦点を置く作りだとマウス操作では誰も触っていない釦に色が付く。作品側で「最後に触ったのが手元機か鍵盤なら出す、マウスなら出さない」のように切り替える。指乗せの色はこの切り替えと無関係に出る。

### 手を入れる

`verify.sh` で、状態ごとの色をヘッドレスで確かめる。

```
./verify.sh
```

## ライセンス

Unlicense（パブリックドメイン）。

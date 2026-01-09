# Design System 設計ルール  
（Colors / TextStyles / ThemeData / Dark Mode）

---

## 目的

- UI コードから数値指定（Color / opacity / fontSize）を排除する
- `withOpacity` 非推奨警告を完全に解消する
- ダークモード対応時のコード増加を最小化する
- デザイン意図を「意味（semantic）」としてコードに残す

---

## 全体構造と責務

UI 実装は以下の 3 レイヤーで構成する。

- **AppTextStyles**  
  文字の構造（階層・大きさ・太さ）を定義する  
  ダークモード非対応・不変

- **AppColors**  
  色の意味・状態・dark/light の違いを吸収する  
  ダークモード対応の唯一の場所

- **ThemeData**  
  AppColors / AppTextStyles を接続する配線レイヤー  
  設計ロジックは持たない

UI 側では色・サイズ・opacity を直接扱わない。

---

## Colors 設計ルール

### 基本方針

- 色の数値（ARGB）はすべて BaseColors に封印する
- UI は AppColors のみを使用する
- opacity は「数値」ではなく「役割」として扱う
- UI 層で `withOpacity` / `withValues` を使用しない

---

### Opacity レイヤー定義

opacity は以下の 4 段階のみを使用する。

- **subtle（0.05 / alpha 13）**  
  装飾・空気感用（限定使用）

- **base（0.1 / alpha 26）**  
  divider / disabled

- **surface（0.2 / alpha 51）**  
  background / gradient / overlay

- **outline（0.3 / alpha 77）**  
  border / shadow / elevation

UI では opacity 値を直接指定しない。

---

### Text 用例外ルール

- Text / Icon / 数字は可読性最優先とする
- 情報を持つ要素に 0.3 以下の opacity は使用しない
- 状態差は opacity ではなく「状態色」で表現する

Text の状態は以下のみを許可する。

- **Active**  
  通常表示（不透明）

- **Inactive**  
  待機・非アクティブ（約 0.7 相当）

---

### ダークモード基本ルール（最重要）

- UI・TextStyle では dark 判定を行わない
- dark/light の違いは AppColors 内で吸収する
- 新しい色は増やさず、gray 階調を反転させて使用する

#### Gray 階調反転ルール

- Light  
  - background：white  
  - surface：gray50  
  - textPrimary：gray900  
  - textSecondary：gray500  
  - divider / outline：gray900 + alpha  

- Dark  
  - background：black  
  - surface：gray900  
  - textPrimary：gray100  
  - textSecondary：gray300  
  - divider / outline：white + alpha  

dark では黒に黒を重ねない。  
装飾・境界は必ず白ベースに切り替える。

---

## Status / Accent Color 指針

### success / error

- 結果を示す「情報色」として扱う
- dark でも色自体は変更しない
- Text / Icon に使用する
- 大面積の背景には直接使用しない

必要な場合のみ soft 版を 1 段追加してよい。

---

### warning / info

- 注意・補足を伝える「通知色」として扱う
- success / error と同じルールで使用する
- Text / Icon 用途に限定する
- dark 用の別色は作らない

---

### primary color

- ブランド色として固定する
- dark では「使う面積」を制限する
- 眩しい場合のみ soft 版を 1 段用意する
- UI 側でテーマ分岐を行わない

---

## TextStyle 設計ルール

### 基本方針

- UI は AppTextStyles のみを使用する
- `TextStyle(...)` の直接生成は禁止
- fontSize / fontWeight は TextStyle 側で固定
- opacity を含めない
- 状態差は Colors で表現する

---

### 命名ルール

TextStyle 名は以下の形式とする。

- `{category}{Size}`

category：
- display / headline / title / body / label / button / numeric

Size：
- Large / Medium / Small

---

### TextStyle の責務

- 情報の階層
- 文字サイズ
- 太さ

TextStyle は以下を持たない。

- 状態（active / inactive）
- ダークモード分岐
- opacity 数値

---

## ThemeData 統合ルール

### 基本方針

- ThemeData は「配線」のみを担当する
- `darkTheme` は使用しない
- 色の実体は AppColors に集約する
- 文字の実体は AppTextStyles に集約する

---

### ThemeData で行うこと

- scaffoldBackgroundColor の指定
- dividerColor の指定
- colorScheme の最小定義
- textTheme に AppTextStyles を流し込む

ThemeData に設計ロジックを持たせない。

---

## 禁止事項（重要）

- UI での `Color(0xFF...)`
- UI での opacity 数値指定
- UI での `withOpacity`
- UI での TextStyle 直接生成
- dark 用に別 Theme / 別 Colors クラスを増やすこと

---

## 設計思想（要約）

数値は意味に変換する  
状態は色で表現する  
ダークモードは Colors に封印する  

ThemeData は中心ではない  
中心は AppColors と AppTextStyles に置く

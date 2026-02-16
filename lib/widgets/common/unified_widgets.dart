import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

/// `lib/widgets/common/unified_widgets.dart` の公開API一覧。
///
/// 直接利用推奨（✅）
/// - [InfoCard]: 汎用情報ブロック。
/// - [InfoItem]: 箇条書き情報行。
/// - [GradientButton]: 主要CTAボタン。
/// - [EmptyStateWidget]: データ無し状態表示。
/// - [LoadingWidget]: ローディング状態表示。
/// - [SectionHeader]: セクション見出し。
/// - [UserAvatar]: 汎用イニシャルアバター。
/// - [ListItemCard]: リスト行カード。
///
/// 直接利用非推奨（❌）
/// - 業務固有文言・権限制御・画面固有レイアウトをこのファイルのWidgetへ直接実装すること。
///   必要な場合は画面側でラップした専用Widgetを作成する。

/// 統一された情報カードウィジェット。
///
/// - 汎用用途: アイコン + タイトル + 任意子要素の情報カード表示。
/// - 依存テーマ: `AppColors.info` / `AppTextStyles.titleSmall` を基本配色として利用。
/// - 禁止用途: 業務依存項目（部署別承認情報や管理指標）を共通カードに固定しない。
class InfoCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final List<Widget> children;
  final Color? backgroundColor;
  final Color? iconColor;
  final EdgeInsets? padding;

  const InfoCard({
    super.key,
    this.icon,
    required this.title,
    required this.children,
    this.backgroundColor,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      color: backgroundColor ?? AppColors.info.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: iconColor ?? AppColors.info,
                    ),
                  ),
                ],
              )
            else
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: iconColor ?? AppColors.info,
                ),
              ),
            if (icon != null || title.isNotEmpty) const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 情報アイテム（チェックマーク付き）。
///
/// - 汎用用途: 説明文の箇条書き行を簡潔に表示。
/// - 依存テーマ: `AppColors.info` / `AppTextStyles.bodySmall`。
/// - 禁止用途: 業務固有ステータスの真偽表示をこの見た目に固定しない。
class InfoItem extends StatelessWidget {
  final String text;
  final Color? color;

  const InfoItem({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: color ?? AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: color ?? AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// グラデーションボタンウィジェット。
///
/// - 汎用用途: 主要アクションの実行ボタン（ローディング対応）。
/// - 依存テーマ: `AppColors.primaryGradient` / `AppTextStyles.buttonMedium`。
/// - 禁止用途: 画面固有の権限制御や確認ダイアログ分岐を内包しない。
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Gradient? gradient;
  final double? height;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.gradient,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading ? null : (gradient ?? AppColors.primaryGradient),
            color: isLoading ? AppColors.divider : null,
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(label, style: AppTextStyles.buttonMedium),
                        ],
                      )
                    : Text(label, style: AppTextStyles.buttonMedium),
          ),
        ),
      ),
    );
  }
}

/// 空の状態を表示するウィジェット。
///
/// - 汎用用途: データ未登録・検索結果なし等の空状態表示。
/// - 依存テーマ: `AppTextStyles.headlineSmall` / `AppColors.textSecondary`。
/// - 禁止用途: 業務フロー固有の復旧手順を固定文言として持たせない。
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (iconColor ?? AppColors.textSecondary).withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor ?? AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ローディング表示ウィジェット。
///
/// - 汎用用途: 非同期処理中の待機状態表示。
/// - 依存テーマ: `AppColors.primary` / `AppTextStyles.bodyMedium`。
/// - 禁止用途: API種別ごとの詳細進捗や障害判定ロジックを実装しない。
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? AppColors.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// セクションヘッダーウィジェット。
///
/// - 汎用用途: アイコン付きのセクション見出し表示。
/// - 依存テーマ: `AppTextStyles.headlineMedium` / `AppColors.primary`。
/// - 禁止用途: 業務依存のフィルタ条件や操作ボタンを見出しへ常設しない。
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: color ?? AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: color ?? AppColors.primary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ユーザーアバターウィジェット。
///
/// - 汎用用途: 名前の頭文字から生成するシンプルなアバター表示。
/// - 依存テーマ: `AppColors.primaryGradient` と Material `BoxShadow`。
/// - 禁止用途: 権限バッジや監査ラベル等の業務依存情報を重畳しない。
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// リストアイテムカードウィジェット。
///
/// - 汎用用途: タイトル/サブタイトル/前後要素を持つ汎用リスト行。
/// - 依存テーマ: `AppTextStyles.bodyLarge` / `AppTextStyles.labelMedium`。
/// - 禁止用途: 業務固有の選択ルールや承認状態遷移を内包しない。
class ListItemCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? borderColor;

  const ListItemCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppConstants.defaultBorderRadius,
        ),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: leading,
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
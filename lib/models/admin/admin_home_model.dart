/// AdminPageState は、管理画面ホームの表示状態（集計値とローディング）を表すモデル。
/// Firestore の永続コレクションではなく、主に UI 状態管理用途で利用する。
///
/// フォーマット規約:
/// - ID/日付/列挙相当値は持たない。
///
/// 関連モデル:
/// - PremiumCounter (`lib/models/admin/premium_counter.dart`) 等の集計値表示に利用される。
class AdminPageState {
  final int paidMemberCount;
  final bool isLoading;

  AdminPageState({
    required this.paidMemberCount,
    required this.isLoading,
  });

  AdminPageState copyWith({
    int? paidMemberCount,
    bool? isLoading,
  }) {
    return AdminPageState(
      paidMemberCount: paidMemberCount ?? this.paidMemberCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

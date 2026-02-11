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

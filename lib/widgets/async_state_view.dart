import 'package:flutter/material.dart';

import '../core/async_state.dart';
import 'empty_state_view.dart';
import 'error_retry_view.dart';
import 'skeleton.dart';

/// Shows an [AsyncState] the same way on every screen: skeleton while
/// loading, [ErrorRetryView] on failure, [empty] when there is nothing, and
/// [data] otherwise. M20 step 4.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.state,
    required this.data,
    this.empty,
    this.loading,
    this.onRetry,
    this.retryKey,
    this.onSignInAgain,
    this.signInAgainLabel,
  });

  final AsyncState<T> state;
  final Widget Function(BuildContext context, T value) data;

  /// Defaults to a bare [EmptyStateView] with no text, so screens should
  /// pass their own.
  final WidgetBuilder? empty;
  final WidgetBuilder? loading;
  final VoidCallback? onRetry;
  final Key? retryKey;
  final VoidCallback? onSignInAgain;
  final String? signInAgainLabel;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () =>
          loading?.call(context) ??
          const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SkeletonList(),
          ),
      data: (v) => data(context, v),
      empty: () => empty?.call(context) ?? const EmptyStateView(title: ''),
      failure: (e) => ErrorRetryView(
        error: e,
        onRetry: onRetry,
        retryKey: retryKey,
        onSignInAgain: onSignInAgain,
        signInAgainLabel: signInAgainLabel,
      ),
    );
  }
}

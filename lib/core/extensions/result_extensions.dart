import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// Extensions on [Result] for common patterns.
extension ResultExtensions<T> on Result<T> {
  /// Returns the data if [Success], otherwise `null`.
  T? get dataOrNull => switch (this) {
        Success(data: final data) => data,
        Failure() => null,
      };

  /// Returns the failure if [Failure], otherwise `null`.
  AppFailure? get failureOrNull => switch (this) {
        Success() => null,
        Failure(failure: final f) => f,
      };
}

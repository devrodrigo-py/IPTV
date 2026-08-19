import 'package:nebula_iptv/core/errors/app_failure.dart';

/// Sealed class representing the result of an operation that can fail.
///
/// Use [Success] for successful results and [Failure] for errors.
/// This ensures the presentation layer never deals with raw exceptions.
sealed class Result<T> {
  const Result();

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Transforms the success value using [transform].
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      Failure(failure: final failure) => Failure(failure),
    };
  }

  /// Executes [onSuccess] or [onFailure] depending on the result.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success(data: final data) => success(data),
      Failure(failure: final f) => failure(f),
    };
  }
}

/// Represents a successful result containing [data].
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result containing an [AppFailure].
final class Failure<T> extends Result<T> {
  final AppFailure failure;

  const Failure(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}

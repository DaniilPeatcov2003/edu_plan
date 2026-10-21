sealed class Result<T> {
  const Result();
}

// Успешный результат с данными.
class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

// Результат с ошибкой.
class Err<T> extends Result<T> {
  const Err(this.message);

  final String message;
}
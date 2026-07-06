import 'dart:async';

sealed class RepoEvent<T> {}

final class RepoItemCreated<T> extends RepoEvent<T> {
  final T item;
  RepoItemCreated(this.item);
}

final class RepoItemUpdated<T> extends RepoEvent<T> {
  final T item;
  RepoItemUpdated(this.item);
}

final class RepoItemDeleted<T> extends RepoEvent<T> {
  final T item;
  RepoItemDeleted(this.item);
}

/// Mixin para inyectar reactividad en cualquier Repositorio.
/// Proporciona un stream de eventos de mutación (RepoEvent) para
/// que los Cubits de lectura puedan reaccionar automáticamente.
mixin ReactiveRepository<T> {
  final _controller = StreamController<RepoEvent<T>>.broadcast();

  Stream<RepoEvent<T>> get eventStream => _controller.stream;

  void notifyItemCreated(T item) {
    if (!_controller.isClosed) {
      _controller.sink.add(RepoItemCreated<T>(item));
    }
  }

  void notifyItemUpdated(T item) {
    if (!_controller.isClosed) {
      _controller.sink.add(RepoItemUpdated<T>(item));
    }
  }

  void notifyItemDeleted(T item) {
    if (!_controller.isClosed) {
      _controller.sink.add(RepoItemDeleted<T>(item));
    }
  }

  void disposeReactiveRepo() {
    _controller.close();
  }
}

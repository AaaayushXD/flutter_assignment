import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

class IncrementCounter extends CounterEvent {
  final int amount;

  const IncrementCounter([this.amount = 1]);

  @override
  List<Object?> get props => [amount];
}

class DecrementCounter extends CounterEvent {
  final int amount;

  const DecrementCounter([this.amount = 1]);

  @override
  List<Object?> get props => [amount];
}

class ResetCounter extends CounterEvent {}

class LoadCounter extends CounterEvent {}

class SaveCounter extends CounterEvent {}

// States
abstract class CounterState extends Equatable {
  const CounterState();

  @override
  List<Object?> get props => [];
}

class CounterInitial extends CounterState {}

class CounterLoading extends CounterState {}

class CounterLoaded extends CounterState {
  final int count;
  final bool isSaving;

  const CounterLoaded({required this.count, this.isSaving = false});

  CounterLoaded copyWith({int? count, bool? isSaving}) {
    return CounterLoaded(
      count: count ?? this.count,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [count, isSaving];
}

class CounterError extends CounterState {
  final String message;

  const CounterError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial()) {
    on<LoadCounter>(_onLoadCounter);
    on<IncrementCounter>(_onIncrementCounter);
    on<DecrementCounter>(_onDecrementCounter);
    on<ResetCounter>(_onResetCounter);
    on<SaveCounter>(_onSaveCounter);
  }

  Future<void> _onLoadCounter(
    LoadCounter event,
    Emitter<CounterState> emit,
  ) async {
    emit(CounterLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('counter') ?? 0;
      emit(CounterLoaded(count: count));
    } catch (e) {
      emit(CounterError('Failed to load counter: $e'));
    }
  }

  Future<void> _onIncrementCounter(
    IncrementCounter event,
    Emitter<CounterState> emit,
  ) async {
    if (state is CounterLoaded) {
      final currentState = state as CounterLoaded;
      final newCount = currentState.count + event.amount;
      emit(currentState.copyWith(count: newCount));

      // Auto-save after increment
      add(SaveCounter());
    }
  }

  Future<void> _onDecrementCounter(
    DecrementCounter event,
    Emitter<CounterState> emit,
  ) async {
    if (state is CounterLoaded) {
      final currentState = state as CounterLoaded;
      final newCount = currentState.count - event.amount;
      emit(currentState.copyWith(count: newCount));

      // Auto-save after decrement
      add(SaveCounter());
    }
  }

  Future<void> _onResetCounter(
    ResetCounter event,
    Emitter<CounterState> emit,
  ) async {
    if (state is CounterLoaded) {
      emit(const CounterLoaded(count: 0));

      // Auto-save after reset
      add(SaveCounter());
    }
  }

  Future<void> _onSaveCounter(
    SaveCounter event,
    Emitter<CounterState> emit,
  ) async {
    if (state is CounterLoaded) {
      final currentState = state as CounterLoaded;

      // Show saving state
      emit(currentState.copyWith(isSaving: true));

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('counter', currentState.count);

        // Remove saving state
        emit(currentState.copyWith(isSaving: false));
      } catch (e) {
        emit(CounterError('Failed to save counter: $e'));
      }
    }
  }
}

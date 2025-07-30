import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object> get props => [];
}

class IncrementCounter extends CounterEvent {}

class DecrementCounter extends CounterEvent {}

class ResetCounter extends CounterEvent {}

// States
abstract class CounterState extends Equatable {
  final int count;

  const CounterState(this.count);

  @override
  List<Object> get props => [count];
}

class CounterInitial extends CounterState {
  const CounterInitial() : super(0);
}

class CounterUpdated extends CounterState {
  const CounterUpdated(super.count);
}

// BLoC
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterInitial()) {
    on<IncrementCounter>(_onIncrementCounter);
    on<DecrementCounter>(_onDecrementCounter);
    on<ResetCounter>(_onResetCounter);
  }

  void _onIncrementCounter(IncrementCounter event, Emitter<CounterState> emit) {
    emit(CounterUpdated(state.count + 1));
  }

  void _onDecrementCounter(DecrementCounter event, Emitter<CounterState> emit) {
    emit(CounterUpdated(state.count - 1));
  }

  void _onResetCounter(ResetCounter event, Emitter<CounterState> emit) {
    emit(const CounterUpdated(0));
  }
}

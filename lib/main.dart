import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ============================================================================
// 1. КЛАССЫ СОСТОЯНИЙ ЭКРАНА (В соответствии с Рисунком 21 из методички)
// ============================================================================
@immutable
abstract class MainScreenState {}

// Состояние №1: Ожидание ввода данных пользователя
class MainScreenInputState extends MainScreenState {}

// Состояние №2: Успешный расчет ИМТ с передачей вычисленных параметров в UI
class MainScreenResultState extends MainScreenState {
  final double bmi;            
  final String category;       
  final String interpretation; 

  MainScreenResultState({
    required this.bmi,
    required this.category,
    required this.interpretation,
  });
}

// Состояние №3: Вывод ошибки при некорректных параметрах ввода
class MainScreenErrorState extends MainScreenState {
  final String errorMessage;
  MainScreenErrorState(this.errorMessage);
}

// ============================================================================
// 2. КЛАСС КУБИТА (В соответствии с Рисунками 22-23 из методички)
// ============================================================================
class MainScreenCubit extends Cubit<MainScreenState> {
  // Инициализация кубита стартовым состоянием ввода данных
  MainScreenCubit() : super(MainScreenInputState());

  // Вынос всех расчетов из уровня представления в уровень бизнес-логики (Пункт 4)
  void calculateBmi(String weightText, String heightText) {
    if (weightText.isEmpty || heightText.isEmpty) {
      emit(MainScreenErrorState("Пожалуйста, заполните все поля"));
      return;
    }

    final double? weight = double.tryParse(weightText);
    final double? heightCm = double.tryParse(heightText);

    if (weight == null || heightCm == null || weight <= 0 || heightCm <= 0) {
      emit(MainScreenErrorState("Введите корректные положительные числа"));
      return;
    }

    final double heightM = heightCm / 100;
    final double bmi = weight / pow(heightM, 2);

    String category;
    String interpretation;

    if (bmi < 18.5) {
      category = "Дефицит массы тела";
      interpretation = "У вас вес ниже нормы. Рекомендуется сбалансировать питание.";
    } else if (bmi >= 18.5 && bmi < 25) {
      category = "Нормальный вес";
      interpretation = "Поздравляем! У вас отличный показатель. Поддерживайте здоровый образ жизни.";
    } else if (bmi >= 25 && bmi < 30) {
      category = "Избыточная масса тела";
      interpretation = "Есть небольшой избыток веса. Обратите внимание на физическую активность.";
    } else {
      category = "Ожирение";
      interpretation = "Показатель значительно превышает норму. Рекомендуется проконсультироваться со специалистом.";
    }

    // Изменение состояния экрана на результат с передачей вычисленных данных
    emit(MainScreenResultState(
      bmi: double.parse(bmi.toStringAsFixed(1)),
      category: category,
      interpretation: interpretation,
    ));
  }

  // Возврат кубита в исходное состояние (сброс данных)
  void reset() {
    emit(MainScreenInputState());
  }
}

// ============================================================================
// 3. ТОЧКА ВХОДА ПРИЛОЖЕНИЯ
// ============================================================================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreenProvider(), // Запуск через провайдер кубита
    );
  }
}

// ============================================================================
// 4. ПРОВАЙДЕР КУБИТА (В соответствии с Рисунком 25 из методички)
// ============================================================================
class MainScreenProvider extends StatelessWidget {
  const MainScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainScreenCubit>(
      create: (context) => MainScreenCubit(),
      child: MainScreen(), // Дочерним виджетом выступает сам экран приложения
    );
  }
}

// ============================================================================
// 5. ЭКРАН ПРИЛОЖЕНИЯ (В соответствии с Рисунком 24 из методички)
// ============================================================================
class MainScreen extends StatelessWidget {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bmi Cubit'), // Стилизовано под название из методички
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      // Вместо переключения экранов через Navigator используется BlocBuilder (Пункт 5)
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: BlocBuilder<MainScreenCubit, MainScreenState>(
          builder: (context, state) {
            if (state is MainScreenResultState) {
              return _buildResultView(context, state);
            }
            if (state is MainScreenErrorState) {
              return _buildErrorView(context, state.errorMessage);
            }
            // По умолчанию возвращается состояние ввода данных MainScreenInputState
            return _buildInputView(context);
          },
        ),
      ),
    );
  }

  // Компонент интерфейса: Экран ввода данных
  Widget _buildInputView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Рост (в см)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.height),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Вес (в кг)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.scale),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: () {
            // Чтение кубита и вызов бизнес-логики расчета (Рисунок 24)
            BlocProvider.of<MainScreenCubit>(context).calculateBmi(
                  _weightController.text,
                  _heightController.text,
                );
          },
          child: const Text('Рассчитать ИМТ', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  // Компонент интерфейса: Экран отображения результатов расчета (Смена состояния)
  Widget _buildResultView(BuildContext context, MainScreenResultState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ваш Индекс Массы Тела:',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            '${state.bmi}',
            style: TextStyle(
              fontSize: 72, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.category,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              state.interpretation,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => BlocProvider.of<MainScreenCubit>(context).reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Пересчитать', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Компонент интерфейса: Экран вывода ошибок валидации
  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => BlocProvider.of<MainScreenCubit>(context).reset(),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }
}

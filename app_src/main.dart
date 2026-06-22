import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HabitApp());

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class Habit {
  String name;
  List<String> completedDates; // ISO yyyy-MM-dd strings

  Habit({required this.name, List<String>? completedDates})
      : completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {'name': name, 'dates': completedDates};

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        name: j['name'] as String,
        completedDates: (j['dates'] as List).cast<String>(),
      );

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get doneToday => completedDates.contains(_key(DateTime.now()));

  void toggleToday() {
    final today = _key(DateTime.now());
    if (completedDates.contains(today)) {
      completedDates.remove(today);
    } else {
      completedDates.add(today);
    }
  }

  int get streak {
    int count = 0;
    DateTime cursor = DateTime.now();
    // If not done today, start counting from yesterday so the streak is preserved.
    if (!completedDates.contains(_key(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (completedDates.contains(_key(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Habit> _habits = [];
  static const _storageKey = 'habits_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      setState(() {
        _habits
          ..clear()
          ..addAll(decoded.map((e) => Habit.fromJson(e as Map<String, dynamic>)));
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_habits.map((h) => h.toJson()).toList()));
  }

  void _addHabit() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New habit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Drink water'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _habits.add(Habit(name: name)));
      _save();
    }
  }

  void _toggle(Habit h) {
    setState(() => h.toggleToday());
    _save();
  }

  void _delete(int index) {
    setState(() => _habits.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doneCount = _habits.where((h) => h.doneToday).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHabit,
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: _habits.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.today, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Text(
                            'Today: $doneCount / ${_habits.length} done',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: _habits.length,
                    itemBuilder: (context, i) {
                      final h = _habits[i];
                      return Dismissible(
                        key: ValueKey('${h.name}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: theme.colorScheme.errorContainer,
                          child: Icon(Icons.delete,
                              color: theme.colorScheme.onErrorContainer),
                        ),
                        onDismissed: (_) => _delete(i),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _toggle(h),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: h.doneToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceVariant,
                                ),
                                child: Icon(
                                  h.doneToday ? Icons.check : Icons.circle_outlined,
                                  color: h.doneToday
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            title: Text(h.name),
                            subtitle: Text('🔥 ${h.streak} day streak'),
                            onTap: () => _toggle(h),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_outlined,
              size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('No habits yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Tap "Habit" to start building one.'),
        ],
      ),
    );
  }
}

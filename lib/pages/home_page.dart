import 'package:flutter/material.dart';
import 'package:habit_tracker/components/my_drawer.dart';
import 'package:habit_tracker/components/my_habit_tile.dart';
import 'package:habit_tracker/components/my_heat_map.dart';
import 'package:habit_tracker/database/habit_database.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/util/habit_util.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // read existing habits on app startup
    Provider.of<HabitDatabase>(context, listen: false).readHabits();
    super.initState();
  }

  // text controller
  final TextEditingController textEditingController = TextEditingController();

  // create new habit
  void createNewHabit() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: TextField(
              controller: textEditingController,
              decoration: InputDecoration(
                hintText: "Create a new habit",
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            actions: [
              // save button
              MaterialButton(
                onPressed: () {
                  //get the new habit name
                  String newHabitName = textEditingController.text;
                  // save to db
                  context.read<HabitDatabase>().addHabit(newHabitName);
                  // pop box
                  Navigator.pop(context);
                  // clear
                  textEditingController.clear();
                },
                child: const Text('Save'),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                  // clear
                  textEditingController.clear();
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  // check habit on & off
  void checkHabitOnOff(bool? value, Habit habit) {
    // update habit completion status
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  // edit habit
  void editHabitBox(Habit habit) {
    // set the controller's text to the habit's current name
    textEditingController.text = habit.name;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: TextField(controller: textEditingController),
            actions: [
              // save button
              MaterialButton(
                onPressed: () {
                  //get the new habit name
                  String newHabitName = textEditingController.text;
                  // save to db
                  context.read<HabitDatabase>().updateHabitName(
                    habit.id,
                    newHabitName,
                  );
                  // pop box
                  Navigator.pop(context);
                  // clear
                  textEditingController.clear();
                },
                child: const Text('Save'),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                  // clear
                  textEditingController.clear();
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  // delete habit box
  void deleteHabitBox(Habit habit) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Are you sure you want to delete?"),
            actions: [
              // save button
              MaterialButton(
                onPressed: () {
                  // save to db
                  context.read<HabitDatabase>().deleteHabit(habit.id);
                  // pop box
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text("Today", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      body: ListView(
        children: [
          // H E A T M A P
          _buildHeatMap(),
          // H A B I T L I S T
          _buildHabitList(),
        ],
      ),
    );
  }

  // build heat map
  Widget _buildHeatMap() {
    // habit database
    final habitDatabase = context.watch<HabitDatabase>();
    // current habit
    List<Habit> currentHabits = habitDatabase.currentHabits;
    // return heat map UI
    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        // once the data is available -> build heatmap
        if (snapshot.hasData) {
          return MyHeatMap(
            startDate: snapshot.data!,
            datasets: prepHeatMapDataset(currentHabits),
          );
        }
        // handle case where no data is returned
        else {
          return Container();
        }
      },
    );
  }

  Widget _buildHabitList() {
    // habit db
    final habitDatabase = context.watch<HabitDatabase>();

    // current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    return ListView.builder(
      itemCount: currentHabits.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        // get each individual habit
        final habit = currentHabits[index];

        // check if the habit
        bool isCompleteToday = isHabitCompletedToday(habit.completeDays);

        // return habit title UI
        return MyHabitTile(
          text: habit.name,
          isCompleted: isCompleteToday,
          onChanged: (value) => checkHabitOnOff(value, habit),
          editHabit: (context) => editHabitBox(habit),
          deleteHabit: (context) => deleteHabitBox(habit),
        );
      },
    );
  }
}

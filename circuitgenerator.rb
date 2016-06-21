# PSEUDOCODE
# Goal: Build an application, driven by a database, that can generate a workout circuit that will be sufficiently "randomized,"
# but adhere to certain parameters; i.e., don't have multiple movements in a row that target the same primary muscle group,
# stick to an overall time limit, and don't have too many "high intensity" movements in a row/over a workout.

# USER INTERFACE
# 1) ask if user wants to (probably do this via a numbered list)
# 	view existing movements in the database
# 	edit a movement in the database
# 	add a movement in the database
# 		need to check for duplicates
# 	remove a movement in the database
# 	generate a circuit
# 	exit
# 2) Editing movements should allow for a change in duration, intensity or target muscle group

# LOGIC

# 1) Database - create DB initially "seeded" with 
# 	Exercises: ID, Movement Name, Muscle Group ID, intensity level (1-3), duration ID
# 	MuscleGroups: ID, GroupName
# 	Durations: ID, Time
# 		Time will be in seconds. Breaking this out, so you can opt to "up the difficulty" later by turning 30 second movments in to 45, etc.
# 2) View existing movements
# 	Call method to print SQL array of rows (rows = db.execute( "select * from test" ))
# 3) Edit movement
# 	User selects movement by ID
# 	Prompt for which field to edit and then it's new value - loop this until they're done editing
# 		Call new method that takes field and new value as parameters then run
# 		db.execute( "update table set ? = ?", field value)
# 4) Add movement
# 	Prompt user for exercise name, muscle group (pull this dynamically?) and intensity level
# 		check if there's a duplicate in name -- if so, puts that movement and exit method
# 5) Remove movement
# 	Provide list of movement with ID
# 	User selects movement by ID
# 	Print movement again, then delete
# 6) Generate a circuit
# 	Set Duration = 0
# 	Create empty array to hold overall routine "routine"
# 	Until loop based on duration -- when each movement is added, add its duration to the total
# 		Create array from SQL select that EXCLUES movements with the muscle group of the routine.last movement (eligible_movements)
# 		Select movement based on a random number takes array as a parameter (eligible_movements) and returns array of movement name and duration
# 		Push this returned array ^^^ to "routine"
# 		Set duration += routine.last[1]
# 	Method to print routine in a pretty fashion

####################################
############BUSINESS LOGIC########
####################################

db = SQLite3::Database.new( "circuit.db" )



####################################
############USER INTERFACE#######
####################################
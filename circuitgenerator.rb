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
# 	Movements: ID, Movement Name, Muscle Group ID, intensity level (1-3), duration ID
# 	MuscleGroups: ID, GroupName
# 	Durations: ID, Time
# 		Time will be in seconds. Breaking this out, so you can opt to "up the difficulty" later by turning 30 second movments in to 45, etc.
# 2) View existing movements
# 	Call method to print SQL array of rows (rows = db.execute( "select * from test" ))
# 3) Edit movement
# 	User selects movement by ID
# 	Prompt for which field to edit and then it's new value - loop this until they're done editing
# 		Call new method that takes movement and field as parameters then ask for new value specific to field
# 		Then run db.execute( "update table set ? = ?", field value)
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

############DATABASE CREATION
	require_relative "stockdata"
	require 'sqlite3'
	db = SQLite3::Database.new( "circuit.db" )

	create_movements_cmd = <<-SQL
	  CREATE TABLE IF NOT EXISTS Movements(
	    id INTEGER PRIMARY KEY,
	    movementName VARCHAR(255),
	    intensity_ID INT,
	    musclegroup_ID INT,
	    duration_ID INT,
	    FOREIGN KEY (musclegroup_ID) REFERENCES musclegroups(ID),
	    FOREIGN KEY (duration_ID) REFERENCES durations(ID),
	    FOREIGN KEY (intensity_ID) REFERENCES intensity(ID)
	  )
	SQL

	create_muscle_groups_cmd = <<-SQL
	  CREATE TABLE IF NOT EXISTS MuscleGroups(
	    id INTEGER PRIMARY KEY,
	    groupname VARCHAR(255)
	  )
	SQL

	create_durations_cmd = <<-SQL
	  CREATE TABLE IF NOT EXISTS Durations(
	    id INTEGER PRIMARY KEY,
	    duration INT
	  )
	SQL

	create_intensity_cmd = <<-SQL
	  CREATE TABLE IF NOT EXISTS Intensity(
	    id INTEGER PRIMARY KEY,
	    Intensity INT
	  )
	SQL

	db.execute(create_durations_cmd)
	db.execute(create_muscle_groups_cmd)
	db.execute(create_movements_cmd)
	db.execute(create_intensity_cmd)

	STOCK_DURATIONS.each do |duration|
		add_stock_durations_cmd = <<-SQL
			insert into Durations (duration) 
			select "#{duration}" 
			where NOT EXISTS
				(SELECT * FROM Durations
				WHERE duration = "#{duration}")
			SQL

		db.execute(add_stock_durations_cmd)
	end

	STOCK_INTENSITY.each do |intensity|
		add_stock_intensity_cmd = <<-SQL
			insert into Intensity (intensity) 
			select "#{intensity}" 
			where NOT EXISTS
				(SELECT * FROM Intensity
				WHERE Intensity = "#{intensity}")
			SQL

		db.execute(add_stock_intensity_cmd)
	end

	STOCK_MUSCLE_GROUPS.each do |muscle_group|
		add_stock_durations_cmd = <<-SQL
			insert into MuscleGroups (groupname) 
			select "#{muscle_group}" 
			where NOT EXISTS
				(SELECT * FROM MuscleGroups
				WHERE groupname = "#{muscle_group}")
			SQL

		db.execute(add_stock_durations_cmd)
	end

	STOCK_MOVEMENTS.each do |movement_array|
		add_stock_movements_cmd = <<-SQL
			insert into Movements (movementName, intensity_id, musclegroup_ID, duration_ID) 
			select "#{movement_array[0]}", "#{movement_array[1]}", "#{movement_array[2]}", "#{movement_array[3]}"
			where NOT EXISTS
				(SELECT * FROM Movements
				WHERE movementName = "#{movement_array[0]}")
		SQL

		db.execute(add_stock_movements_cmd)
	end


############BUSINESS LOGIC

	def view_movement_library(db)
		puts "==========================================="
		movements = db.execute(<<-SQL
			select mv.id, Movementname, groupname, duration, intensity
			from Movements mv
			    join durations d on mv.duration_id = d.id
			    join musclegroups mg on mv.musclegroup_id = mg.id
			    join intensity inte on mv.intensity_id = inte.id
			SQL
			)
		movements.each do |movearray|
			puts "#{movearray[0]}: #{movearray[1]}, Group=#{movearray[2]}, Duration (sec)=#{movearray[3]}, Intensity=#{movearray[4]} \n\n"
		end
		puts "==========================================="
	end


############METHODS RELATED TO DATABASE CHANGES

	def edit_movement_check_response (response, db, sql)
		while !(db.execute(sql).flatten.include?(response.to_i))
			puts 'That is not a valid value. Please specify again.'
			response=gets.chomp
		end
		return response
	end

	def edit_movement_options(db, dbtable)
			puts "Please select an option by number below:"
			db.execute("select * from #{dbtable}").each do |group|
				puts "#{group[0]}: #{group[1]}"
			end
			puts"----------------------"
			user_selection=gets.chomp
			user_selection=edit_movement_check_response(user_selection.to_i, db, "SELECT id FROM #{dbtable}").to_i
	end

	def edit_movement_commit_change(db, field, newvalue, movement_to_change)
		db.execute("update Movements set #{field}=#{newvalue} where id=#{movement_to_change}")
	end

	def edit_movement_detail (db, movement, aspect)
			case aspect
			when 1 
				then new_value = edit_movement_options(db, "MuscleGroups")
				edit_movement_commit_change(db, "musclegroup_ID", new_value, movement)
			when 2 
				then new_value = edit_movement_options(db, "durations")
				edit_movement_commit_change(db, "duration_ID", new_value, movement)
			when 3 
				then new_value = edit_movement_options(db, "intensity")
				edit_movement_commit_change(db, "intensity_ID", new_value, movement)
			else
			end
	end

	def edit_movement (db)
		view_movement_library(db)
		puts "Please select the movement you'd like to edit by number or type 'exit.'"
			selected_movement=gets.chomp
				selected_movement=edit_movement_check_response(selected_movement.to_i, db, "SELECT id FROM movements")
		puts "Please select which aspect (by number) you'd like to change: \n1: Group \n2: Duration \n3: Intensity"
			selected_aspect=gets.chomp
			while !((1..3)===selected_aspect.to_i)
				puts 'That is not a valid value. Please specify again.'
				selected_aspect=gets.chomp
			end
		edit_movement_detail(db, selected_movement, selected_aspect.to_i)
	end

############METHODS RELATED TO DATABASE ADDITIONS

	def add_movement_check_duplicate(db, new_movement)
		existing_movements = db.execute("select movementName from movements").flatten
		existing_movements.map! do |movement| 
			movement.downcase
		end
		existing_movements.include?(new_movement.downcase)
	end

	def add_movement_push_to_db(db, new_movement, muscle_group, duration, intensity)
		db.execute(
			<<-SQL
			INSERT INTO movements (movementname, intensity_ID, musclegroup_ID, duration_ID) 
			values (
			"#{new_movement}",
			"#{intensity}",
			"#{muscle_group}",
			"#{duration}"
			)
			SQL
			)
	end

	def add_movement(db)
		puts "Please enter exercise name:"
		new_movement=gets.chomp
		if add_movement_check_duplicate(db, new_movement)
				puts "That exercise is already in the database"
		else
			puts "----------------------\nMuscle Group?"
			muscle_group = edit_movement_options(db, "MuscleGroups")
			puts "----------------------\nDuration?"
			duration = edit_movement_options(db, "durations")
			puts "----------------------\nIntensity?"
			intensity = edit_movement_options(db, "intensity")
			add_movement_push_to_db(db, new_movement, muscle_group, duration, intensity)
		end
	end

############METHODS RELATED TO DATABASE DELETIONS
	def delete_movement(db, movement_ID)
		db.execute("DELETE FROM movements where id = #{movement_ID}")
	end

	def remove_movement_confirm(db, movement_ID)
		movementname = db.execute("SELECT movementname FROM movements where id = #{movement_ID}").flatten
		puts "Are you sure you want to delete #{movementname[0]} (y/n)?"
		confirm=gets.chomp
			if confirm[0].downcase=="y"
				delete_movement(db,movement_ID)
				return true
			else 
				return false
			end
	end

	def remove_movement (db)
		view_movement_library(db)
		confirmed=false
		while !confirmed
			puts "Please select a movement to remove by number or type 'exit'"
			response = gets.chomp
			if response.downcase == "exit"
				confirmed=true
			elsif !db.execute("select id from movements").flatten.include?(response.to_i)
				puts "That is not a valid selection"
			else confirmed=remove_movement_confirm(db, response.to_i)
			end
		end

	end

############METHODS RELATED TO GENERATION OF CIRCUIT

	def create_new_circuit_get_next (db, last_muscle_group)
		movement_array=db.execute("
						select movementName, duration, musclegroup_id
						from movements mv 
						join durations d on d.id = mv.duration_id 
						where musclegroup_ID <> #{last_muscle_group}
						"
						)
		movement_array[rand(0..movement_array.length-1)]
	end 

	def create_new_circuit(db)
		duration=0
		circuit=[]
		while duration < 900
			if !(circuit.length == 0)
				last_muscle_group = circuit.last[2]
			else last_muscle_group = 0
			end
			next_move = create_new_circuit_get_next(db, last_muscle_group).flatten
			circuit.push(next_move)
			duration += circuit.last[1]
		end
		return circuit
	end

####################################
############USER INTERFACE#######
####################################

selection = 0
while selection != 6
	puts <<-MENU
--------------------------------------------------------------------
What would you like to do? (Select by number)
	1) View the available movements
	2) Generate a circuit
	3) Add a movement
	4) Delete a movement
	5) Update details of a movement
	6) Exit
--------------------------------------------------------------------
		MENU
	selection=gets.chomp.to_i
	case selection
	when 0
		then
	when 1
		then view_movement_library(db)
	when 2
		puts "----------------------"
		create_new_circuit(db).each do |movements|
			puts "#{movements[0]}: #{movements[1]} seconds"
		end
		puts "----------------------"
	when 3
		then add_movement(db)
	when 4
		then remove_movement(db)
	when 5
		then edit_movement(db)
	end	
end
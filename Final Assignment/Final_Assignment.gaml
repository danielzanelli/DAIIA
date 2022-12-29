/**
* Name: FinalAssignment
* Based on the internal skeleton template. 
* Author: Mehdi, Daniel
* Tags: 
*/

model FinalAssignment

global {
	int nb_stages <- 6;
	int nb_ppl <- 12;
	
	float view_dist<-1000.0;
	float speed <- 2#km/#h;
	float amplitude <- 120.0;
	
//	market the_market;
	
	string music_location_pr_name <- "music_at_location";
	string drink_location_pr_name <- "drink_at_location";
	string food_location_pr_name <- "food_at_location";
	
//	string lookingForStageString <- "Looking for an interesting stage";
//	predicate lookingForStage <- new_predicate(lookingForStageString);
//    
//	string foundStageWithMusicString <- "Found a stage with music";
//	predicate foundStageWithMusic <- new_predicate(foundStageWithMusicString);
//	
	float step <- 10#mn;
	
	//possible predicates concerning miners

	predicate no_need_wander_pr <- new_predicate('no_need_wander') ;  // for belief
	
	predicate music_need_pr <- new_predicate('music_need') ; // for belief
	predicate drink_need_pr <- new_predicate('drink_need') ; // for belief
	predicate food_need_pr <- new_predicate('food_need') ; // for belief
	
	predicate wander_music_pr <- new_predicate("wander_music") ;  // for desire, intention
	predicate wander_drink_pr <- new_predicate("wander_drink") ;  // for desire, intention
	predicate wander_food_pr <- new_predicate("wander_food") ;  // for desire, intention
	
	predicate music_location_pr <- new_predicate(music_location_pr_name) ; // for belief
	predicate drink_location_pr <- new_predicate(drink_location_pr_name) ; // for belief
	predicate food_location_pr <- new_predicate(food_location_pr_name) ; // for belief
	
	predicate satisfy_music_pr <- new_predicate("satisfy_music"); // for desire, intention, belief
	predicate satisfy_drink_pr <- new_predicate("satisfy_drink"); // for desire, intention, belief
	predicate satisfy_food_pr <- new_predicate("satisfy_food"); // for desire, intention, belief
	
	predicate socialize_pr <- new_predicate("socialize"); // for desire, intention, belief
	
	predicate share_information_pr <- new_predicate("share_information") ; // for desire, intention
	
	
	string same_profession_people_pr_name <- "same_profession_people";
	string date_list_pr_name <- 'date_list';
	string sugar_list_pr_name <- 'sugar_list';
	
	
	predicate same_profession_people_pr <- new_predicate(same_profession_people_pr_name) ; // for belief
	
	
	predicate fan_chat_pr <- new_predicate("fan_chat_pr") ; // for desire, intention
	predicate dance_together_pr <- new_predicate("dance_together_pr") ; // for desire, intention
	predicate sing_together_pr <- new_predicate("sing_together_pr") ; // for desire, intention
	predicate split_bill_date_pr <- new_predicate("split_bill_date_pr") ; // for desire, intention
	predicate pay_whole_bill_date_pr <- new_predicate("pay_whole_bill_date_pr") ; // for desire, intention
	
	
	emotion joy_music <- new_emotion("joy", satisfy_music_pr);
	emotion joy_drink <- new_emotion("joy", satisfy_drink_pr);
	emotion joy_food <- new_emotion("joy", satisfy_food_pr);
	
//	float inequality <- 0.0 update:standard_deviation(Person collect each.gold_sold);
	
	geometry shape <- square(20 #km);
	init
	{
//		create market {
//			the_market <- self;	
//		}
		create Stage number: nb_stages;
		create Person number: nb_ppl;
	}
	
	reflex display_social_links{
		loop tempMiner over: Person{
				loop tempDestination over: tempMiner.social_link_base{
					if (tempDestination !=nil){
						bool exists<-false;
						loop tempLink over: socialLinkRepresentation{
							if((tempLink.origin=tempMiner) and (tempLink.destination=tempDestination.agent)){
								exists<-true;
							}
						}
						if(not exists){
							create socialLinkRepresentation number: 1{
								origin <- tempMiner;
								destination <- tempDestination.agent;
								if(get_liking(tempDestination)>0){
									my_color <- #green;
								} else {
									my_color <- #red;
								}
							}
						}
					}
				}
			}
	}
	
//	reflex end_simulation when: sum(Stage collect each.remaining_capacity) = 0 and empty(Person where each.has_belief(satisfy_music_pr)){
//		do pause;
//		ask Person {
//			write name + " : " +gold_sold;
//		}
//	}
}

species Stage {
    int type <- rnd(1,3);
    bool has_music <- false;
    bool has_drink <- false;
    bool has_food <- false;
    init {
    	if (type = 1){
    		has_music <- true;
    	}
    	if (type = 2){
    		has_drink <- true;
    	}
    	if (type = 3) {
    		has_food <- true;
    	}
    }
    
    aspect default {
        draw triangle(700) color: #yellow border: #black;    
    }
}

//species market {
//	int golds;
//	aspect default {
//		draw square(1000) color: #black ;
//	}
//}

species Person skills: [moving, fipa] control:simple_bdi {
	
	rgb my_color<-rnd_color(255);
	
	int need_music <- 0;
    int need_drink <- 0;
    int need_food <- 0;
    
    string profession <- sample(['fan', 'fan', 'fan'],1,false)[0];
    
    bool is_young <- flip(0.5);
    bool is_female <- flip(0.0);
    
    
    bool use_personality <- true;
	float openness <- float(rnd(1)); // open-minded
	float conscientiousness <- 0.5; //  act with preprations
	float extroversion <- 1.0; //float(rnd(1)); // extrovert
	float agreeableness <- float(rnd(1)); // friendly
	float neurotism <- float(rnd(1)); // calm
	
    map<string,float> liking <- [];
//    bool is_generous <- flip(0.5);
//    bool is_humble <- flip(0.5);
	
	point target_stage_loc;
	
    bool use_social_architecture <- true;
	bool use_emotions_architecture <- true;
	
	init {
		do add_desire(no_need_wander_pr);
	}

	plan lets_wander intention:no_need_wander_pr { // finished_when: (has_belief_with_name('music_need') or has_belief_with_name('drink_need') or has_belief_with_name('food_need')) {
		do wander speed: speed amplitude: amplitude;
	}
	
	reflex inate_need_model {
		need_music <- need_music + 1;
		need_drink <- need_drink + 1;
		need_food <- need_food + 1;
		
		if need_music = 31 {
			do add_belief(music_need_pr);
			do remove_intention(no_need_wander_pr, false);
			write name + ': now need music';
		}
		if need_drink = 10 {
			do add_belief(drink_need_pr);
			do remove_intention(no_need_wander_pr, false);
			write name + ': now need drink';
		}
		if need_food = 23 {
			do add_belief(food_need_pr);
			do remove_intention(no_need_wander_pr, false);
			write name + ': now need food';
		}
	}
	
	
	// detect the concerts that are not full (i.e. the quantity of prticipants
	// is lower than capacity) at a distance lower or equal to view_dist
	perceive target: Stage in: view_dist {
		//	Myself: Person
		//	Self: Stage
		if (self.has_music) { // and myself.has_belief_with_name('music_need')
			// adding for each detected concert a belief corresponding to the
			// location of this concert. The name of the belief will be
			// concert_at_location and the location value of the concert will
			// be stored in the values (a map) variable of the belief at the
			// key location_value.
			
			//is equivalent to:
			//	ask myself {
			//		do add_belief(new_predicate("stage_location_pr_name",["location_value"::myself.location]);
			//	}
			focus id: music_location_pr_name var: location;
			write myself.name + ': added ' + self.name + ' location to my music belief';
			
			//	the instructions written in the statement are executed in the
			//	context of the perceived agents. It is for that, that we have to
			//	use the myself keyword to ask the MusicFan agent to execute the
			//	remove_intention action, allowing the agent to choose a new intention.
			ask myself {
				//	check if the emotion is in the belief base.
				//	Myself: Stage
				//	Self: Person
				if (has_emotion(joy_music)) {
					write self.name + ': ' + " enjoying the music in " + myself.name;
					do add_desire(predicate:share_information_pr, strength: 6.0);
				}
				do remove_intention(wander_music_pr, true);
			}
		}
		if (self.has_drink and myself.has_belief_with_name('drink_need')) {
			focus id: drink_location_pr_name var: location;
			write myself.name + ': ' + " added " + self.name + ' location to my drink belief';
			
			ask myself {
	//			check if the emotion is in the belief base.
	//			Myself: Stage
	//			Self: Person
//				if (has_emotion(joy_drink)) {
//					write self.name + ': ' + " enjoying the drink in " + myself.name;
//					do add_desire(predicate:share_information_pr, strength: 6.0);
//				}
				do remove_intention(wander_drink_pr, true);
			}
		}
		if (self.has_food) {
			focus id: food_location_pr_name var: location;
			write myself.name + ': ' + " added " + self.name + ' location to my food belief';
			
			ask myself {
	//			check if the emotion is in the belief base.
	//			Myself: Stage
	//			Self: Person
				if (has_emotion(joy_food)) {
					write self.name + ': ' + " enjoying the food in " + myself.name;
					do add_desire(predicate:share_information_pr, strength: 6.0);
				}
				do remove_intention(wander_food_pr, true);
			}
		}
	}

		
	// if the agent believes that there is somewhere at least one
	// concert_location, the agent gets the new desire to has a gold nugget with a strength of 2. 
	rule belief: music_need_pr new_desire: satisfy_music_pr strength: 2.0;
	rule belief: drink_need_pr new_desire: satisfy_drink_pr strength: 4.0;
	rule belief: food_need_pr new_desire: satisfy_food_pr strength: 3.0;
	
	plan go_to_music intention: satisfy_music_pr {
		list<point> possible_stages;
		if (target_stage_loc = nil) {
			possible_stages <- get_beliefs_with_name(music_location_pr_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			if (empty(possible_stages)) {
				do add_subintention(get_current_intention(),wander_music_pr, true);
				do current_intention_on_hold();
			}
			else {
				target_stage_loc <- (possible_stages with_min_of (each distance_to self)).location;
			}
		}
		else {
			do goto target: target_stage_loc ;
			if (target_stage_loc = location)  {
				Stage current_stage<- Stage first_with (target_stage_loc = each.location);
				do add_belief(satisfy_music_pr);
				if (has_emotion(joy_music)) {
					write self.name + ': ' + " enjoying the music in " + current_stage;
					do add_desire(predicate:share_information_pr, strength: 6.0);
				}
				target_stage_loc <- nil;
			}
		}
	}

	plan lets_wander_music intention:wander_music_pr finished_when: has_belief_with_name(music_location_pr_name){
		do wander speed: speed amplitude: amplitude;
	}
	
	
	plan go_to_drink intention: satisfy_drink_pr {
		list<point> possible_stages;
		if (target_stage_loc = nil) {
			possible_stages <- get_beliefs_with_name(drink_location_pr_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			if (empty(possible_stages)) {
				do add_subintention(get_current_intention(),wander_drink_pr, true);
				do current_intention_on_hold();
			}
			else {
				target_stage_loc <- (possible_stages with_min_of (each distance_to self)).location;
			}
		}
		else {
			do goto target: target_stage_loc ;
			if (target_stage_loc = location)  {
				Stage current_stage<- Stage first_with (target_stage_loc = each.location);
				do add_belief(satisfy_drink_pr);
				if (has_emotion(joy_drink)) {
					write self.name + ': ' + " enjoying the drink in " + current_stage;
					do add_desire(predicate:share_information_pr, strength: 6.0);
				}
				target_stage_loc <- nil;
			}
		}
	}
	
	plan lets_wander_drink intention:wander_drink_pr finished_when: has_belief_with_name(drink_location_pr_name){
		do wander speed: speed amplitude: amplitude;
	}


	plan go_to_food intention: satisfy_food_pr {
		list<point> possible_stages;
		if (target_stage_loc = nil) {
			possible_stages <- get_beliefs_with_name(food_location_pr_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			if (empty(possible_stages)) {
				do add_subintention(get_current_intention(),wander_food_pr, true);
				do current_intention_on_hold();
			}
			else {
				target_stage_loc <- (possible_stages with_min_of (each distance_to self)).location;
			}
		}
		else {
			do goto target: target_stage_loc ;
			if (target_stage_loc = location)  {
				Stage current_stage<- Stage first_with (target_stage_loc = each.location);
				do add_belief(satisfy_food_pr);
				if (has_emotion(joy_food)) {
					write self.name + ': ' + " enjoying the food in " + current_stage;
					do add_desire(predicate:share_information_pr, strength: 6.0);
				}
				target_stage_loc <- nil;
			}
		}	
	}

	plan lets_wander_food intention:wander_food_pr finished_when: has_belief_with_name(food_location_pr_name){
		do wander speed: speed amplitude: amplitude;
	}
	
	rule belief: satisfy_music_pr remove_belief: music_need_pr remove_desire: satisfy_music_pr;
	rule belief: satisfy_drink_pr remove_belief:drink_need_pr remove_desire: satisfy_drink_pr;
	rule belief: satisfy_food_pr remove_belief: food_need_pr remove_desire: satisfy_food_pr;
	
	rule belief: satisfy_music_pr new_desire: socialize_pr strength: 5 lifetime: 30;
	rule belief: satisfy_drink_pr new_desire: socialize_pr strength: 5 lifetime: 30;
	rule belief: satisfy_food_pr new_desire: socialize_pr strength: 5 lifetime: 30;

//	string profession <- sample(['singer', 'dancer', 'fan'],1,false)[0];
//
//	bool is_young <- flip(0.5);
//	bool is_female <- flip(0.5);
//
//	bool use_personality <- true;
//	float openness <- float(rnd(1)); // open-minded
//	float conscientiousness <- 0.5; //  act with preprations
//	float extroversion <- float(rnd(1)); // extrovert
//	float agreeableness <- float(rnd(1)); // friendly
//	float neurotism <- float(rnd(1)); // calm

	perceive target:Person in:view_dist {
		//	Myself: I
		//	Self: other
		if (myself.is_current_intention(socialize_pr) and self.is_current_intention(socialize_pr)) {
			// if mypersonality is this formula, else another formula
			float sim_distance <- (point(self.openness, self.extroversion, self.agreeableness, self.neurotism) distance_to point(myself.openness, myself.extroversion, myself.agreeableness, myself.neurotism));
			write myself.name + ': sim_distance with ' + self.name + ' is ' + sim_distance;
			socialize liking: 1.0 -  sim_distance;
			liking[myself.name] <- ((myself.social_link_base where (each.agent = self)) collect each.liking)[0];
			
			// job
			if (self.profession = myself.profession) {
				//is equivalent to:
				ask myself {
					//	Myself: other
					//	Self: I
					do add_belief(new_predicate(same_profession_people_pr_name,["self_value"::myself]));
				}
//				focus id: same_profession_people_pr_name var: name;
				write myself.name + ': added ' + self.name + ' name to my same profession belief';
				
				ask myself {
					//	Myself: other
					//	Self: I

					if (self.extroversion=1.0) {
						if (self.profession='fan'){
							write self.name + ': ' + " going to ask for a fan chat with " + myself.name;
							do add_subintention(get_current_intention(),new_predicate("fan_chat_pr", myself), true);
							do current_intention_on_hold();
//							do add_desire(predicate:fan_chat_pr, strength: 5.0);
						}
						if (self.profession='dancer'){
							write self.name + ': ' + " going to ask for a dance with " + myself.name;
							do add_subintention(get_current_intention(),dance_together_pr, true);
							do current_intention_on_hold();
//							do add_desire(predicate:dance_together_pr, strength: 5.0);
						}
						if (self.profession='singer'){
							write self.name + ': ' + " going to ask for a sing with " + myself.name;
							do add_subintention(get_current_intention(),sing_together_pr, true);
							do current_intention_on_hold();
//							do add_desire(predicate:sing_together_pr, strength: 5.0);
						}
					}
//					do remove_intention(find_prefered_stage_pr, false);
				}
			}
			
			// date list
			if (myself.is_young = self.is_young and myself.is_female != self.is_female){
				focus id: date_list_pr_name var: name;
				write myself.name + ': ' + " added " + self.name + ' name to my date list belief';
				ask myself {
					//	Myself: other
					//	Self: I

					if (self.extroversion=1.0) {
						if (self.liking[myself.name] > 0.5 ){
							write self.name + ': ' + "intention to ask for a split-bill date with " + myself.name;
							do add_subintention(get_current_intention(), split_bill_date_pr, true);
							do current_intention_on_hold();
//							do add_desire(predicate:fan_chat_pr, strength: 5.0);
						}
					}
				}	
			}
			
			// sugar date list !!
			if (myself.is_young != self.is_young and myself.is_female != self.is_female){
				focus id: sugar_list_pr_name var: name;
				write myself.name + ': ' + " added " + self.name + ' name to my sugar list belief';
				ask myself {
					//	Myself: other
					//	Self: I

					if (self.extroversion=1.0) {
						if (self.liking[myself.name] > 0.5 ){
							write self.name + ': ' + "intention to ask for a pay-whole-bill date with " + myself.name;
							do add_subintention(get_current_intention(), pay_whole_bill_date_pr, true);
							do current_intention_on_hold();
//							do add_desire(predicate:fan_chat_pr, strength: 5.0);
						}
					}
				}	
			}
		}
	}

//	rule belief: same_profession_people_pr new_desire: socialize_pr strength: 2.5;
//	rule belief: socialize_drink_pr remove_desire: socialize_drink_pr;

	plan stay_at_stage intention: socialize_pr {
		list temp <- get_beliefs_with_name('satisfy_drink');
		if not empty(temp) {
			do remove_belief(satisfy_drink_pr);
		}
		
		temp <- get_beliefs_with_name('satisfy_food');
		if not empty(temp) {
			do remove_belief(satisfy_food_pr);
		}
		
		temp <- get_beliefs_with_name('satisfy_music');
		if not empty(temp) {
			do remove_belief(satisfy_music_pr);
		}
//		if (need_music > 31) {
//			need_music <- 0;
//			do remove_belief(satisfy_music_pr);
//			need_drink <- 0;
//			do remove_belief(satisfy_drink_pr);
//			need_food <- 0;
//			do remove_belief(satisfy_food_pr);
//		}
// wait 10 sec, then flip your needs again
		
//		do goto target: the_market ;
//		if (the_market.location = location)  {
//			do remove_belief(satisfy_music_pr);
//			do remove_intention(sell_gold_pr, true);
//			gold_sold <- gold_sold + 1;
//		}
	}
	
	
	plan fan_chat intention: fan_chat_pr {
		list<Person> all_chat_targets <- get_beliefs_with_name(same_profession_people_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
		write self.name + ': current intention cause : ' + get_predicate(get_current_intention());
//		list<Person> already_met <- get_beliefs_with_name(same_profession_people_met_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
//		list<Person> new_chat_targets <- all_chat_targets - already_met;
		Person target_chat <- all_chat_targets[0];
		// remove the target belief 
		ask target_chat {
			//	Myself: I
			//	Self: target
			if (self.extroversion=1.0) {
				write myself.name + ': ' + " fan chat request with " + self.name + ' accepted and finished';
				ask myself {
					do remove_belief(same_profession_people_pr);
					do remove_intention(fan_chat_pr, true);
					do remove_intention(socialize_pr, true);
				}
				do remove_belief(same_profession_people_pr);
				do remove_intention(fan_chat_pr, true); 
				do remove_intention(socialize_pr, true);
			}
			else {
				write myself.name + ': ' + " fan chat request with " + self.name + ' rejected, try with another one';
				do remove_intention(fan_chat_pr, true); 
			}
		}
	}
	
	plan dance_together intention: dance_together_pr {
		
	}
	
	plan sing_together intention: sing_together_pr {
		
	}
	
	plan split_bill_date intention: split_bill_date_pr {
		
	}
	
	plan pay_whole_bill_date intention: pay_whole_bill_date_pr {
		
	}
	
	plan share_information_to_friends intention: share_information_pr instantaneous: true {
		list<Person> my_friends <- list<Person>((social_link_base where (each.liking > 0)) collect each.agent);
		if (!empty(my_friends)) {
			loop known_gold_mine over: get_beliefs_with_name(music_location_pr_name) {
				write self.name + ': sharing this (' + known_gold_mine + ') with my friends ';
					do start_conversation to:my_friends performative:'inform' contents:known_gold_mine;
	//			ask my_friends {
	//				do add_directly_belief(known_gold_mine);
	//			}
			}
		}
		do remove_intention(share_information_pr, true); 
	}
	
	reflex write_inform_msg when: !empty(informs) {
		message informFromInitiator <- (informs at 0);
		do add_directly_belief(informFromInitiator.contents[0]);
		write self.name + ': received inform msg, ' + informFromInitiator.contents[0];
	}

	aspect default {
	    draw circle(200) color: my_color border: #black depth: 10;
	    draw circle(view_dist) color: my_color border: #black depth: 20 wireframe: true;
	}
}

species socialLinkRepresentation{
	Person origin;
	agent destination;
	rgb my_color;
	
	aspect base{
		draw line([origin,destination],50.0) color: my_color;
	}
}


experiment gui_experiment type: gui {
	
	output {
		display map type: opengl {
//			species market;
			species Stage;
			species Person;
		}
		
		display socialLinks type: opengl {
        	species socialLinkRepresentation aspect: base;
    	}

//		display chart {
//			chart "Money" type: series {
//				datalist legend: Person accumulate each.name value: Person accumulate each.gold_sold color: Person accumulate each.my_color;
//			}
//		}
		
	}
}

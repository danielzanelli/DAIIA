/**
* Name: FinalAssignment
* Based on the internal skeleton template. 
* Author: Mehdi, Daniel
* Tags: 
*/

model FinalAssignment

global {
	
	int number_of_rejections <- 0;
	int number_of_dates <- 0;
	int number_of_interactions <- 0;
	
	int nb_stages <- 10;
	int nb_ppl <- 50;
	
	float view_dist<-1000.0;
	float speed <- 2#km/#h;
	float amplitude <- 120.0;
	
	int music_alarm <- 43;
	int drink_alarm <- 23;
	int food_alarm <- 31;
	
	int socialize_wait <- 10;
	float liking_share_threshold <- 0.5;	
	
	float openness_chance <- 0.5; 				// open-minded
	float conscientiousness_chance <- 0.5; 		// act with preprations
	float extroversion_chance <- 0.5; 			// extrovert
	float agreeableness_chance <- 0.5; 			// friendly
	float neurotism_chance <- 0.5;				// not-calm
	
	string music_location_pr_name <- "music_at_location";
	string drink_location_pr_name <- "drink_at_location";
	string food_location_pr_name <- "food_at_location";
	
	float step <- 10#mn;

	predicate no_need_wander_pr <- new_predicate('no_need_wander') ;  			// for belief
	
	predicate music_need_pr <- new_predicate('music_need') ; 					// for belief
	predicate drink_need_pr <- new_predicate('drink_need') ; 					// for belief
	predicate food_need_pr <- new_predicate('food_need') ; 						// for belief
	
	predicate wander_music_pr <- new_predicate("wander_music") ;  				// for desire, intention
	predicate wander_drink_pr <- new_predicate("wander_drink") ;  				// for desire, intention
	predicate wander_food_pr <- new_predicate("wander_food") ;  				// for desire, intention
	
	predicate music_location_pr <- new_predicate(music_location_pr_name) ; 		// for belief
	predicate drink_location_pr <- new_predicate(drink_location_pr_name) ; 		// for belief
	predicate food_location_pr <- new_predicate(food_location_pr_name) ; 		// for belief
	
	predicate satisfy_music_pr <- new_predicate("satisfy_music"); 				// for desire, intention, belief
	predicate satisfy_drink_pr <- new_predicate("satisfy_drink"); 				// for desire, intention, belief
	predicate satisfy_food_pr <- new_predicate("satisfy_food"); 				// for desire, intention, belief
	
	predicate socialize_pr <- new_predicate("socialize"); 						// for desire, intention, belief
	
	predicate share_information_pr <- new_predicate("share_information") ; 		// for desire, intention
	
	
	string same_profession_people_pr_name <- "same_profession_people";
	string date_list_pr_name <- 'date_list';
	string sugar_list_pr_name <- 'sugar_list';
	
	
	predicate same_profession_people_pr <- new_predicate(same_profession_people_pr_name); 	// for belief
	predicate date_list_pr <- new_predicate(date_list_pr_name) ; 							// for belief
	predicate sugar_list_pr <- new_predicate(sugar_list_pr_name) ; 							// for belief
	
	
	predicate fan_chat_pr <- new_predicate("fan_chat") ; 						// for desire, intention
	predicate dance_together_pr <- new_predicate("dance_together") ; 			// for desire, intention
	predicate sing_together_pr <- new_predicate("sing_together") ; 				// for desire, intention
	predicate split_bill_date_pr <- new_predicate("split_bill_date") ; 			// for desire, intention
	predicate pay_whole_bill_date_pr <- new_predicate("pay_whole_bill_date") ; 	// for desire, intention
	
	
	emotion joy_music <- new_emotion("joy", satisfy_music_pr);
	emotion joy_drink <- new_emotion("joy", satisfy_drink_pr);
	emotion joy_food <- new_emotion("joy", satisfy_food_pr);
	
	
	geometry shape <- square(20 #km);
	init
	{
		create Stage number: nb_stages;
		create Person number: nb_ppl;
	}
	
	reflex display_social_links{
		loop tempPerson over: Person{
				loop tempDestination over: tempPerson.social_link_base{
					if (tempDestination !=nil){
						bool exists<-false;
						loop tempLink over: socialLinkRepresentation{
							if((tempLink.origin=tempPerson) and (tempLink.destination=tempDestination.agent)){
								exists<-true;
							}
						}
						if(not exists){
							create socialLinkRepresentation number: 1{
								origin <- tempPerson;
								destination <- tempDestination.agent;
								if(get_liking(tempDestination) >= liking_share_threshold){
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

species Person skills: [moving, fipa] control:simple_bdi {
	
	rgb my_color<-rnd_color(255);
	
	float total_liking <- 0.0;
	
	int need_music <- 0;
    int need_drink <- 0;
    int need_food <- 0;
    
    string profession <- sample(['singer', 'dancer', 'fan'],1,false)[0];
    
    bool is_young <- flip(0.5);
    bool is_female <- flip(0.5);
    
    
    bool use_personality <- true;
    bool use_social_architecture <- true;
	bool use_emotions_architecture <- true;
    
	float openness <- float(flip(openness_chance)); 					// open-minded
	float conscientiousness <- float(flip(conscientiousness_chance)); 	// act with preprations
	float extroversion <- float(flip(extroversion_chance)); 			// extrovert
	float agreeableness <- float(flip(agreeableness_chance)); 			// friendly
	float neurotism <- float(flip(neurotism_chance)); 					// not-calm
	
    map<string,float> liking_map <- [];
	
	point target_stage_loc;
	
	
	init {
		do add_desire(no_need_wander_pr);
	}

	plan lets_wander intention:no_need_wander_pr {
		do wander speed: speed amplitude: amplitude;
	}
	
	reflex inate_need_model {
		
		self.total_liking <- sum(Person collect each.liking_map[self.name]);
		
		need_music <- need_music + 1;
		need_drink <- need_drink + 1;
		need_food <- need_food + 1;
		
		if need_music = music_alarm {
			do add_belief(music_need_pr);
			do remove_intention(no_need_wander_pr, false);
			write name + ': now need music';
		}
		if need_drink = drink_alarm {
			do add_belief(drink_need_pr);
			do remove_intention(no_need_wander_pr, false);
			write name + ': now need drink';
		}
		if need_food = food_alarm {
			do add_belief(food_need_pr);
			do remove_intention(no_need_wander_pr, false);
			write name + ': now need food';
		}
	}	
	

	perceive target: Stage in: view_dist {
		//	Myself: Person
		//	Self: Stage
		if (self.has_music ) {
			
			bool is_present <- false;
			loop belief over: myself.get_beliefs_with_name(music_location_pr_name){
				if(get_predicate(belief).values["location_value"] = location){
					is_present <- true;
					break;
				}
			}
			
			if(!is_present){
				focus id: music_location_pr_name var: location;				
				write myself.name + ': added ' + self.name + ' location to my music belief';				
			}

			ask myself {
//					Myself: Stage
//					Self: Person
				do remove_intention(wander_music_pr, true);
			}
		}
		if (self.has_drink ) {
			
			bool is_present <- false;
			loop belief over: myself.get_beliefs_with_name(drink_location_pr_name){
				if(get_predicate(belief).values["location_value"] = location){
					is_present <- true;
					break;
				}
			}
			
			if(!is_present){
				focus id: drink_location_pr_name var: location;
				write myself.name + ": added " + self.name + ' location to my drink belief';
			}
			
			ask myself {
//				Myself: Stage
//				Self: Person
				do remove_intention(wander_drink_pr, true);
			}
		}
		if (self.has_food) {
			bool is_present <- false;
			loop belief over: myself.get_beliefs_with_name(food_location_pr_name){
				if(get_predicate(belief).values["location_value"] = location){
					is_present <- true;
					break;
				}
			}			
			if(!is_present){
				focus id: food_location_pr_name var: location;
				write myself.name + ': ' + " added " + self.name + ' location to my food belief';
			}
			ask myself {
//				Myself: Stage
//				Self: Person
				do remove_intention(wander_food_pr, true);
			}
		}
	}

		
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
					write self.name + ": enjoying the music in " + current_stage;
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
					write self.name + ": enjoying the drink in " + current_stage;
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
					write self.name + ": enjoying the food in " + current_stage;
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
	
	rule belief: satisfy_music_pr new_desire: socialize_pr strength: 5 lifetime: socialize_wait;
	rule belief: satisfy_drink_pr new_desire: socialize_pr strength: 5 lifetime: socialize_wait;
	rule belief: satisfy_food_pr new_desire: socialize_pr strength: 5 lifetime: socialize_wait;


	perceive target:Person in:view_dist {
//			Myself: I
//			Self: other
		if (myself.is_current_intention(socialize_pr) and self.is_current_intention(socialize_pr)) {
			if!(self.name in myself.liking_map.keys){
				float sim_distance <- ( abs(myself.openness - self.openness) + abs(myself.extroversion - self.extroversion) + abs(myself.agreeableness - self.agreeableness) +  abs(myself.neurotism - self.neurotism) + abs(myself.conscientiousness - self.conscientiousness))/5;
				socialize liking: 1.0 -  sim_distance;
				myself.liking_map[self.name] <- 1.0 - sim_distance;
				write myself.name + ': initial liking with ' + self.name + ' is ' +  (1.0 - sim_distance);
			}
			
//			Profession based activities
			if (self.profession = myself.profession) {
				
				bool is_present <- false;
				loop belief over: myself.get_beliefs_with_name(same_profession_people_pr_name){
					if(get_predicate(belief).values["self_value"] = self){
						is_present <- true;
						break;
					}
				}			
				if(!is_present){
					ask myself {
//							Myself: other
//							Self: I
						do add_belief(new_predicate(same_profession_people_pr_name,["self_value"::myself]));
						write myself.name + ': added ' + self.name + ' name to my same profession belief';
					}
				}
				ask myself {
//						Myself: other
//						Self: I
					if (self.extroversion=1.0 and self.liking_map[myself.name] >= liking_share_threshold ) {
						if (self.profession='fan'){
							write self.name + ": going to ask for a fan chat with " + myself.name;
							do add_subintention(get_current_intention(),new_predicate("fan_chat", myself), true);
							do current_intention_on_hold();
						}
						if (self.profession='dancer'){
							write self.name + ": going to ask for a dance with " + myself.name;
							do add_subintention(get_current_intention(),new_predicate("dance_together", myself), true);
							do current_intention_on_hold();
						}
						if (self.profession='singer'){
							write self.name + ": going to ask for a sing with " + myself.name;
							do add_subintention(get_current_intention(),new_predicate("sing_together", myself), true);
							do current_intention_on_hold();
						}
					}
				}
			}
			
//			Split bill date list
			if (myself.is_young = self.is_young and myself.is_female != self.is_female){
				
				bool is_present <- false;
				loop belief over: myself.get_beliefs_with_name(date_list_pr_name){
					if(get_predicate(belief).values["self_value"] = self){
						is_present <- true;
						break;
					}
				}			
				if(!is_present){
					ask myself {
//							Myself: other
//							Self: I
						do add_belief(new_predicate(date_list_pr_name,["self_value"::myself]));
						write myself.name + ": added " + self.name + ' name to my date list belief';
					}
				}				
				
				ask myself {
//						Myself: other
//						Self: I

					if (self.extroversion=1.0) {
						if (self.liking_map[myself.name] >= liking_share_threshold ){
							write self.name + ": intention to ask for a split-bill date with " + myself.name;
							do add_subintention(get_current_intention(), split_bill_date_pr, true);
							do current_intention_on_hold();
						}
					}
				}	
			}
			
//			Sugar date list
			if (myself.is_young != self.is_young and myself.is_female != self.is_female){				
				
				bool is_present <- false;
				loop belief over: myself.get_beliefs_with_name(sugar_list_pr_name){
					if(get_predicate(belief).values["self_value"] = self){
						is_present <- true;
						break;
					}
				}			
				if(!is_present){
					ask myself {
//							Myself: other
//							Self: I
						do add_belief(new_predicate(sugar_list_pr_name,["self_value"::myself]));
						write myself.name + ": added " + self.name + ' name to my sugar list belief';
					}
				}
				ask myself {
//						Myself: other
//						Self: I
					if (self.extroversion=1.0) {
						if (self.liking_map[myself.name] >= liking_share_threshold ){
							write self.name + ": intention to ask for a pay-whole-bill date with " + myself.name;
							do add_subintention(get_current_intention(), pay_whole_bill_date_pr, true);
							do current_intention_on_hold();
						}
					}
				}	
			}
		}
	}


	plan stay_at_stage intention: socialize_pr {
		list temp <- get_beliefs_with_name('satisfy_drink');
		if not empty(temp) {
			do remove_belief(satisfy_drink_pr);
			need_drink <- 0;
		}
		
		temp <- get_beliefs_with_name('satisfy_food');
		if not empty(temp) {
			do remove_belief(satisfy_food_pr);
			need_food <- 0;
		}
		
		temp <- get_beliefs_with_name('satisfy_music');
		if not empty(temp) {
			do remove_belief(satisfy_music_pr);
			need_music <- 0;
		}
	}
	
	
	plan fan_chat intention: fan_chat_pr {
		list<Person> all_chat_targets <- get_beliefs_with_name(same_profession_people_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
		Person target_chat <- all_chat_targets[0];
		ask target_chat {
			//	Myself: I
			//	Self: target
			if (self.extroversion = 1.0 or self.openness = 1.0 or self.agreeableness = 1.0) {
				write myself.name + ": fan chat request with " + self.name + ' accepted and finished';
				
				number_of_interactions <- number_of_interactions + 1;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 1.1;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 1.1;
				
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
				write myself.name + ": fan chat request has been rejected by " + self.name;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 0.9;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 0.9;

				number_of_rejections <- number_of_rejections + 1;
				
				ask myself {
					do remove_belief(same_profession_people_pr);
					do remove_intention(fan_chat_pr, true);
				}
				do remove_belief(same_profession_people_pr);
				do remove_intention(fan_chat_pr, true);
			}
		}
	}
	
	plan dance_together intention: dance_together_pr {
		list<Person> all_chat_targets <- get_beliefs_with_name(same_profession_people_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
		Person target_chat <- all_chat_targets[0];
		ask target_chat {
			//	Myself: I
			//	Self: target
			if (self.extroversion = 1.0 or self.openness = 1.0 or self.agreeableness = 1.0) {
				write myself.name + ": dance request with " + self.name + ' accepted and finished';
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 1.1;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 1.1;
				
				number_of_interactions <- number_of_interactions + 1;
				
				ask myself {
					do remove_belief(same_profession_people_pr);
					do remove_intention(dance_together_pr, true);
					do remove_intention(socialize_pr, true);
				}
				do remove_belief(same_profession_people_pr);
				do remove_intention(dance_together_pr, true); 
				do remove_intention(socialize_pr, true);
			}
			else {
				write myself.name + ": dance request has been rejected by " + self.name;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 0.9;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 0.9;
				
				number_of_rejections <- number_of_rejections + 1;
				
				ask myself {
					do remove_belief(same_profession_people_pr);
					do remove_intention(dance_together_pr, true);
				}
				do remove_belief(same_profession_people_pr);
				do remove_intention(dance_together_pr, true);
			}
		}
	}
	
	plan sing_together intention: sing_together_pr {
		list<Person> all_chat_targets <- get_beliefs_with_name(same_profession_people_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
		Person target_chat <- all_chat_targets[0];
		ask target_chat {
			//	Myself: I
			//	Self: target
			if (self.extroversion = 1.0 or self.openness = 1.0 or self.agreeableness = 1.0) {
				write myself.name + ": sing request with " + self.name + ' accepted and finished';
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 1.1;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 1.1;
				
				number_of_interactions <- number_of_interactions + 1;
				
				ask myself {
					do remove_belief(same_profession_people_pr);
					do remove_intention(sing_together_pr, true);
					do remove_intention(socialize_pr, true);
				}
				do remove_belief(same_profession_people_pr);
				do remove_intention(sing_together_pr, true); 
				do remove_intention(socialize_pr, true);
			}
			else {
				write myself.name + ": sing request has been rejected by " + self.name;
				
				number_of_rejections <- number_of_rejections + 1;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 0.9;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 0.9;
				
				ask myself {
					do remove_belief(same_profession_people_pr);
					do remove_intention(sing_together_pr, true);
				}
				do remove_belief(same_profession_people_pr);
				do remove_intention(sing_together_pr, true);
			}
		}
	}
	
	plan split_bill_date intention: split_bill_date_pr {
		list<Person> all_chat_targets <- get_beliefs_with_name(date_list_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
		Person target_chat <- all_chat_targets[0];
		ask target_chat {
			//	Myself: I
			//	Self: target
			if (self.extroversion = 1.0 or self.openness = 1.0 or self.agreeableness = 1.0) {
				write myself.name + ": split-bill date with " + self.name + ' accepted and finished';
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 1.1;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 1.1;
				
				number_of_dates <- number_of_dates + 1;
				
				ask myself {
					do remove_belief(date_list_pr);
					do remove_intention(split_bill_date_pr, true);
					do remove_intention(socialize_pr, true);
				}
				do remove_belief(date_list_pr);
				do remove_intention(split_bill_date_pr, true); 
				do remove_intention(socialize_pr, true);
			}
			else {
				write myself.name + ": split-bill date request has been rejected by " + self.name;
				
				number_of_rejections <- number_of_rejections + 1;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 0.9;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 0.9;
				
				ask myself {
					do remove_belief(date_list_pr);
					do remove_intention(split_bill_date_pr, true);
				}
				do remove_belief(date_list_pr);
				do remove_intention(split_bill_date_pr, true);
			}
		}
	}
	
	plan pay_whole_bill_date intention: pay_whole_bill_date_pr {
		list<Person> all_chat_targets <- get_beliefs_with_name(sugar_list_pr_name) collect (get_predicate(mental_state (each)).values["self_value"]);
		Person target_chat <- all_chat_targets[0];
		ask target_chat {
			//	Myself: I
			//	Self: target
			if (self.extroversion = 1.0 or self.openness = 1.0 or self.agreeableness = 1.0) {
				write myself.name + ": split-bill date with " + self.name + ' accepted and finished';
				
				number_of_dates <- number_of_dates + 1;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 1.1;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 1.1;
				ask myself {
					do remove_belief(sugar_list_pr);
					do remove_intention(pay_whole_bill_date_pr, true);
					do remove_intention(socialize_pr, true);
				}
				do remove_belief(sugar_list_pr);
				do remove_intention(pay_whole_bill_date_pr, true); 
				do remove_intention(socialize_pr, true);
			}
			else {
				write myself.name + ": pay-whole-bill date request has been rejected by " + self.name;
				
				number_of_rejections <- number_of_rejections + 1;
				
				myself.liking_map[self.name] <- myself.liking_map[self.name] * 0.9;
				self.liking_map[myself.name] <- self.liking_map[myself.name] * 0.9;
				
				ask myself {
					do remove_belief(sugar_list_pr);
					do remove_intention(pay_whole_bill_date_pr, true);
				}
				do remove_belief(sugar_list_pr);
				do remove_intention(pay_whole_bill_date_pr, true);
			}
		}
	}
	
	plan share_information_to_friends intention: share_information_pr instantaneous: true {
		list<Person> my_friends <- list<Person>((social_link_base where (each.liking > liking_share_threshold)) collect each.agent);
		if (!empty(my_friends)) {
			loop belief over: get_beliefs_with_name(music_location_pr_name) {
					do start_conversation to:my_friends performative:'inform' contents:belief;
			}
		}
		do remove_intention(share_information_pr, true); 
	}
	
	reflex write_inform_msg when: !empty(informs) {
		
		message informFromInitiator <- (informs at 0);		
		bool is_present <- false;
		loop belief over: self.get_beliefs(get_predicate(informFromInitiator.contents[0])){
			if(get_predicate(belief).values["location_value"] = get_predicate(informFromInitiator.contents[0]).values["location_value"]){
				is_present <- true;
				break;
			}
		}
		if (!is_present){
			do add_directly_belief(informFromInitiator.contents[0]);
			write self.name + ': received new location info from friend: ' + get_predicate(informFromInitiator.contents[0]);
		}
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
	parameter "nb_ppl" category: "Agents" var:nb_ppl;
	parameter "nb_stages" category: "Agents" var:nb_stages;
	parameter "view_dist" var:view_dist;
	parameter "speed" var:speed;	
	parameter "amplitude" var:amplitude;	
	parameter "music_alarm" var:music_alarm;
	parameter "drink_alarm" var:drink_alarm;
	parameter "food_alarm" var:food_alarm;
	parameter "socialize_wait" var:socialize_wait;
	parameter "liking_share_threshold" var:liking_share_threshold min:0.0 max:1.0 ;
	
	
	parameter "openness_chance" category: "Agents" var:openness_chance  min:0.0 max:1.0;
	parameter "conscientiousness_chance" category: "Agents" var:conscientiousness_chance  min:0.0 max:1.0;
	parameter "extroversion_chance" category: "Agents" var:extroversion_chance  min:0.0 max:1.0;
	parameter "agreeableness_chance" category: "Agents" var:agreeableness_chance  min:0.0 max:1.0;
	parameter "neurotism_chance" category: "Agents" var:neurotism_chance  min:0.0 max:1.0;

	output {
		display map type: opengl {
			species Stage;
			species Person;
		}
		
		display socialLinks type: opengl {
        	species socialLinkRepresentation aspect: base;
    	}    
    	
		display chart1 {
			chart "Likeness" type: series {
				data legend: "liking" value: sum(Person collect each.total_liking) color: #black;
				data legend: "extrovert liking" value: sum(Person where (each.extroversion = 1.0) collect each.total_liking) color: #red;
				data legend: "introvert liking" value: sum(Person where (each.extroversion = 0.0) collect each.total_liking) color: #blue;
				data legend: "open liking" value: sum(Person where (each.openness = 1.0) collect each.total_liking) color: #green;
				data legend: "non-open liking" value: sum(Person where (each.openness = 0.0) collect each.total_liking) color: #orange;
			}
		}
		
		display chart2 {
			chart "Events" type: series {
				data legend: "professional interactions" value: number_of_interactions color: #blue;
				data legend: "dates" value: number_of_dates color: #green;
				data legend: "rejections" value: number_of_rejections color: #red;
			}
		}	
		
	}
	
}

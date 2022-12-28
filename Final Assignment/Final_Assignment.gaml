/**
* Name: FinalAssignment
* Based on the internal skeleton template. 
* Author: Mehdi, Daniel
* Tags: 
*/

model FinalAssignment

global {
	int nb_stages <- 10;
	int nb_ppl <- 10;
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

	predicate find_prefered_stage_pr <- new_predicate("find prefered stage") ;  // for desire, intention, belief
	
	predicate music_location_pr <- new_predicate(music_location_pr_name) ; // for belief
	predicate drink_location_pr <- new_predicate(drink_location_pr_name) ; // for belief
	predicate food_location_pr <- new_predicate(food_location_pr_name) ; // for belief
	
	predicate choose_stage_pr <- new_predicate("choose a stage"); // for belief
	
	predicate satisfy_music_pr <- new_predicate("satisfy music"); // for desire, intention, belief
	predicate satisfy_drink_pr <- new_predicate("satisfy drink"); // for desire, intention, belief
	predicate satisfy_food_pr <- new_predicate("satisfy food"); // for desire, intention, belief
	
	predicate socialize_music_pr <- new_predicate("socialize during music"); // for desire, intention, belief
	predicate socialize_drink_pr <- new_predicate("socialize during drink"); // for desire, intention, belief
	predicate socialize_food_pr <- new_predicate("socialize during food"); // for desire, intention, belief
	
	predicate share_information_pr <- new_predicate("share information") ; // for desire, intention
	predicate sell_gold_pr <- new_predicate("sell gold") ; // for desire, intention
	
	
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
    bool has_music <- flip(0.5);
    bool has_drink <- flip(1.0);
    bool has_food <- flip(0.5);
    
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
	
	float view_dist<-1000.0;
	float speed <- 2#km/#h;
	rgb my_color<-rnd_color(255);
	
	bool need_music <- flip(0.5);
    bool need_drink <- flip(1.0);
    bool need_food <- flip(0.5);
    
    string profession <- sample(['singer', 'dancer', 'fan'],1,false)[0];
    
    bool is_young <- flip(0.5);
    bool is_female <- flip(0.5);
    
    bool use_personality <- true;
	float openness <- float(rnd(1)); // open-minded
	float conscientiousness <- 0.5; //  act with preprations
	float extroversion <- float(rnd(1)); // extrovert
	float agreeableness <- float(rnd(1)); // friendly
	float neurotism <- float(rnd(1)); // calm
    
//    bool is_generous <- flip(0.5);
//    bool is_humble <- flip(0.5);
	
	point target;
	
    bool use_social_architecture <- true;
	bool use_emotions_architecture <- true;
	
	init {
		do add_desire(find_prefered_stage_pr);
	}
	
	
	// detect the concerts that are not full (i.e. the quantity of prticipants
	// is lower than capacity) at a distance lower or equal to view_dist
	perceive target: Stage in: view_dist {
		
		if (self.has_music and myself.need_music) {
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
			write myself.name + ': ' + " added " + self.name + ' location to my music belief';
			
			//	the instructions written in the statement are executed in the
			//	context of the perceived agents. It is for that, that we have to
			//	use the myself keyword to ask the MusicFan agent to execute the
			//	remove_intention action, allowing the agent to choose a new intention.
			ask myself {
				//	check if the emotion is in the belief base.
				//	Myself: Stage
				//	Self: Person
				if (has_emotion(joy_music)) {
					write self.name + ': ' + " enjoyed the music in " + myself.name;
					do add_desire(predicate:share_information_pr, strength: 5.0);
				}
				do remove_intention(find_prefered_stage_pr, false);
			}
		}
		if (self.has_drink and myself.need_drink) {
			focus id: drink_location_pr_name var: location;
			write myself.name + ': ' + " added " + self.name + ' location to my drink belief';
			
			ask myself {
	//			check if the emotion is in the belief base.
	//			Myself: Stage
	//			Self: Person
				if (has_emotion(joy_drink)) {
					write self.name + ': ' + " enjoyed the drink in " + myself.name;
					do add_desire(predicate:share_information_pr, strength: 5.0);
				}
				do remove_intention(find_prefered_stage_pr, false);
			}
		}
		if (self.has_food and myself.need_food) {
			focus id: food_location_pr_name var: location;
			write myself.name + ': ' + " added " + self.name + ' location to my food belief';
			
			ask myself {
	//			check if the emotion is in the belief base.
	//			Myself: Stage
	//			Self: Person
				if (has_emotion(joy_drink)) {
					write self.name + ': ' + " enjoyed the drink in " + myself.name;
					do add_desire(predicate:share_information_pr, strength: 5.0);
				}
				do remove_intention(find_prefered_stage_pr, false);
			}
		}
	}

		
	// if the agent believes that there is somewhere at least one
	// concert_location, the agent gets the new desire to has a gold nugget with a strength of 2. 
	rule belief: music_location_pr new_desire: satisfy_music_pr strength: 2.0;
	rule belief: drink_location_pr new_desire: satisfy_drink_pr strength: 4.0;
	rule belief: food_location_pr new_desire: satisfy_food_pr strength: 3.0;
	
	plan lets_wander intention:find_prefered_stage_pr finished_when: has_desire(satisfy_music_pr){
		do wander;
	}
	
	plan go_to_music intention: satisfy_music_pr {
		list<point> possible_stages;
		if (target = nil) {
			possible_stages <- get_beliefs_with_name(music_location_pr_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			target <- (possible_stages with_min_of (each distance_to self)).location;
		}
		else {
			do goto target: target ;
			if (target = location)  {
				Stage current_stage<- Stage first_with (target = each.location);
				do add_belief(satisfy_music_pr);
				target <- nil;
			}
		}	
	}
	
	plan go_to_drink intention: satisfy_drink_pr {
		list<point> possible_stages;
		if (target = nil) {
			possible_stages <- get_beliefs_with_name(drink_location_pr_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			target <- (possible_stages with_min_of (each distance_to self)).location;
		}
		else {
			do goto target: target ;
			if (target = location)  {
				Stage current_stage<- Stage first_with (target = each.location);
				do add_belief(satisfy_drink_pr);
				target <- nil;
			}
		}	
	}

	plan go_to_food intention: satisfy_food_pr {
		list<point> possible_stages;
		if (target = nil) {
			possible_stages <- get_beliefs_with_name(food_location_pr_name) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			target <- (possible_stages with_min_of (each distance_to self)).location;
		}
		else {
			do goto target: target ;
			if (target = location)  {
				Stage current_stage<- Stage first_with (target = each.location);
				do add_belief(satisfy_food_pr);
				target <- nil;
			}
		}	
	}
	
	rule belief: satisfy_music_pr new_desire: socialize_music_pr strength: 2.5;
	rule belief: satisfy_drink_pr new_desire: socialize_drink_pr strength: 2.5;
	rule belief: satisfy_food_pr new_desire: socialize_food_pr strength: 2.5;

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
		if is_current_intention(socialize_drink_pr) {
			//	Myself: I
			//	Self: other
			
			// if mypersonality is this formula, else another formula
			socialize liking: 1 -  point(self.openness, self.extroversion, self.agreeableness, self.neurotism) distance_to point(myself.openness, myself.extroversion, myself.agreeableness, myself.neurotism);
			
			// job
			if (self.profession = myself.profession) {
				//is equivalent to:
				//	ask myself {
				//		do add_belief(new_predicate("stage_location_pr_name",["location_value"::myself.location]);
				//	}
				focus id: same_profession_people_pr_name var: name;
				write myself.name + ': ' + " added " + self.name + ' name to my same proffession belief';
				
				ask myself {
					//	Myself: other
					//	Self: I

					if (self.extroversion=1.0) {
						if (self.profession='fan'){
							write self.name + ': ' + " going to have a fan chat with " + myself.name;
							do add_subintention(get_current_intention(),fan_chat_at_drink_intent, true);
							do current_intention_on_hold();
//							do add_desire(predicate:fan_chat_pr, strength: 5.0);
						}
						if (self.profession='dancer'){
							write self.name + ': ' + " going to dance with " + myself.name;
							do add_subintention(get_current_intention(),dance_together_at_drink_intent, true);
							do current_intention_on_hold();
//							do add_desire(predicate:dance_together_pr, strength: 5.0);
						}
						if (self.profession='singer'){
							write self.name + ': ' + " going to sing with " + myself.name;
							do add_subintention(get_current_intention(),sing_together_at_drink_intent, true);
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
						if (self.profession='fan'){
							write self.name + ': ' + " going to have a fan chat with " + myself.name;
							do add_subintention(get_current_intention(),fan_chat_at_drink_intent, true);
							do current_intention_on_hold();
//							do add_desire(predicate:fan_chat_pr, strength: 5.0);
						}
						if (self.profession='dancer'){
							write self.name + ': ' + " going to dance with " + myself.name;
							do add_subintention(get_current_intention(),dance_together_at_drink_intent, true);
							do current_intention_on_hold();
//							do add_desire(predicate:dance_together_pr, strength: 5.0);
						}
						if (self.profession='singer'){
							write self.name + ': ' + " going to sing with " + myself.name;
							do add_subintention(get_current_intention(),sing_together_at_drink_intent, true);
							do current_intention_on_hold();
//							do add_desire(predicate:sing_together_pr, strength: 5.0);
						}
					}
			}
			
			// sugar dady/mom list !!
			if (myself.is_young != self.is_young and myself.is_female != self.is_female){
				focus id: sugar_list_pr_name var: name;
				write myself.name + ': ' + " added " + self.name + ' name to my sugar list belief';
			}
		}
	}

	rule belief: socialize_pr new_desire: socialize_pr strength: 2.5;

	plan stay_at_stage intention: socialize_pr {
		// wait 10 sec, then flip your needs again
		
//		do goto target: the_market ;
//		if (the_market.location = location)  {
//			do remove_belief(satisfy_music_pr);
//			do remove_intention(sell_gold_pr, true);
//			gold_sold <- gold_sold + 1;
//		}
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


//sculpture
//SCP-173, nothing more need be said
/mob/living/simple_animal/sculpture
	name = "\improper sculpture"
	real_name = "sculpture"
	desc = "It's some kind of human sized, doll-like sculpture, with weird discolourations on some parts of it. It appears to be quite solid. "
	icon = 'code/WorkInProgress/Cael_Aislinn/unknown.dmi'
	icon_state = "sculpture"
	icon_living = "sculpture"
	icon_dead = "sculpture"
	emote_hear = list("makes a faint scraping sound")
	emote_see = list("twitches slightly", "shivers")
	response_help  = "touches the"
	response_disarm = "pushes the"
	response_harm   = "hits the"
	var/obj/item/weapon/grab/G
	var/observed = 0
	var/allow_escape = 0	//set this to 1 for src to drop it's target next Life() call and try to escape
	var/hibernate = 0
	var/random_escape_chance = 5 //5 times out of 100 he'll just yakkety sax away, pretty powerful, think of it as blinking

/mob/living/simple_animal/sculpture/proc/GrabMob(var/mob/living/target)
	if(target && target != src && ishuman(target))
		G = new /obj/item/weapon/grab(src, target)
		G.loc=src
		target.grabbed_by += G
		G.synch()
		target.LAssailant = src

		playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
		visible_message("\red [src] snapped [target]'s neck !")
		target << "\red <b>In the blink of an eye, something grabs you and snaps your neck!</b> Everything goes black..."

		G.state = GRAB_KILL

		desc = "It's some kind of human sized, doll-like sculpture, with weird discolourations on some parts of it. It appears to be quite solid. [G ? "\red The sculpture is holding [G.affecting] in a vice-like grip." : ""]"
		target.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been grabbed by SCP-173, and had his neck snapped!</font>")
		log_admin("[target] ([target.ckey]) has been grabbed and had his neck snapped.")
		message_admins("Alert: [target.real_name] has been grabbed and had his neck snapped.") //Set var/allow_escape = 1 to allow this player to escape temporarily, or var/hibernate = 1 to disable it entirely.

/mob/living/simple_animal/sculpture/proc/Escape()
	var/list/turfs = new/list()
	for(var/turf/thisturf in view(50,src))
		if(istype(thisturf, /turf/space))
			continue
		else if(istype(thisturf, /turf/simulated/wall))
			continue
		else if(istype(thisturf, /turf/unsimulated/mineral))
			continue
		else if(istype(thisturf, /turf/simulated/shuttle/wall))
			continue
		else if(istype(thisturf, /turf/unsimulated/wall))
			continue
		turfs += thisturf
	var/turf/target_turf = pick(turfs)
	src.dir = get_dir(src, target_turf)
	src.loc = target_turf

	hibernate = 1
	spawn(rand(20,35) * 10)
		hibernate = 0

/mob/living/simple_animal/sculpture/Life()

	observed = 0

	//update the desc
	if(!G)
		desc = "It's some kind of human sized, doll-like sculpture, with weird discolourations on some parts of it. It appears to be quite solid."

	//if we are sent into forced hibernation mode, allow our victim to escape
	if(hibernate && G && G.state == GRAB_KILL)
		if(G)
			G.affecting << "\red You suddenly feel the grip around your neck being loosened!"
			visible_message("\red [src] suddenly loosens it's grip and seems to calm down!")
			G.state = GRAB_AGGRESSIVE
		return

	//
	if(allow_escape)
		allow_escape = 0
		if(G)
			G.affecting << "\red You suddenly feel the grip around your neck being loosened!"
			visible_message("\red [src] suddenly loosens it's grip!")
			G.state = GRAB_AGGRESSIVE
			if(!observed)
				Escape()
		observed = 1

	//space part removed to avoid mass driving
	//can't do anything in space at all
	if(hibernate)
		return

	// Grabbing
	if(G)
		G.process()

	for(var/mob/living/M in view(7, src))
		if(M.stat || M == src)
			continue
		var/xdif = M.x - src.x
		var/ydif = M.y - src.y
		if(abs(xdif) <  abs(ydif))
			//testing with PERFECT line of sight (aka lined up)
			//mob is either above or below src
			if(ydif < 0 && M.dir == NORTH)
				//mob is below src and looking up
				observed = 1
				break
			else if(ydif > 0 && M.dir == SOUTH)
				//mob is above src and looking down
				observed = 1
				break
		else if(abs(xdif) >  abs(ydif))
			//mob is either left or right of src
			if(xdif < 0 && M.dir == EAST)
				//mob is to the left of src and looking right
				observed = 1
				break
			else if(xdif > 0 && M.dir == WEST)
				//mob is to the right of src and looking left
				observed = 1
				break
		else if (xdif == 0 && ydif == 0)
			//mob is on the same tile as src
			observed = 0
			//breaks the sculpture since it's target can observe it, changed to observed = 0
			break

	//account for darkness
	var/turf/T = get_turf(src)
	var/in_darkness = 0
	if(T.luminosity == 0 && !istype(T, /turf/simulated))
		in_darkness = 1

	//see if we're able to do stuff
	if(!observed || in_darkness)
		if(G)
			if(prob(1))
				//chance to allow the stranglee to escape
				allow_escape = 1
			if(G.affecting.stat == 2)
				del G
				// For some reason I can't remove the next thing, consider it cursed
		else if(!G)
			//see if we're able to strangle anyone
			var/turf/myTurf = get_turf(src)
			for(var/mob/living/M in myTurf)
				GrabMob(M)
				break
				// The curse ends there

			//find out what mobs we can see (-tried to- remove sight and doubled range)
			//var/list/incapacitated = list()
			var/list/conscious = list()
			for(var/mob/living/carbon/M in view(7, src))
				//this may not be quite the right test
				if(M == src)
					continue
				//if(M.stat == 1)
					//incapacitated.Add(M)
				//else if(!M.stat)
				if (!M.stat)
					conscious.Add(M)

			//pick the nearest valid conscious target
			var/mob/living/carbon/target
			for(var/mob/living/carbon/M in conscious)
				if(!target || get_dist(src, M) < get_dist(src, target))
					target = M

			//Please stop raping incapped people
			//if(!target)
				//get an unconscious mob
				//for(var/mob/living/carbon/M in incapacitated)
					//if(!target || get_dist(src, M) < get_dist(src, target))
						//target = M
			if(target)
				var/turf/target_turf
				if(in_darkness)
					//move to right behind them
					target_turf = get_step(target, src)
				else
					//move to them really really fast and knock them down
					target_turf = get_turf(target)

				//rampage along a path to get to them, in the blink of an eye
				var/turf/next_turf = get_step_towards(src, target)
				var/num_turfs = get_dist(src,target)
				while(get_turf(src) != target_turf && num_turfs > 0)
					for(var/obj/structure/window/W in next_turf)
						spawn(5) W.destroy()
					for(var/obj/structure/table/O in next_turf)
						spawn(5) O.ex_act(1)
					for(var/obj/structure/grille/G in next_turf)
						spawn(5) G.ex_act(1)
					for(var/obj/machinery/door/D in next_turf)
						spawn(5) D.open()
					if(!next_turf.CanPass(src, next_turf))
						break
					src.loc = next_turf
					src.dir = get_dir(src, target)
					next_turf = get_step(src, get_dir(next_turf,target))
					num_turfs--

				//if we reached them, knock them down and start strangling them
				if(get_turf(src) == target_turf)
					GrabMob(target)
					target.Stun(1)
					target.Paralyse(1)
					target.apply_damage(150, BRUTE, "head")

					//Should be better now

			//if we're not strangling anyone, take a stroll
			if(!G && prob(50)) //Half chance out of whatever
				var/list/turfs = new/list()
				for(var/turf/thisturf in view(7,src))
					if(istype(thisturf, /turf/space))
						continue
					else if(istype(thisturf, /turf/simulated/wall))
						continue
					else if(istype(thisturf, /turf/unsimulated/mineral))
						continue
					else if(istype(thisturf, /turf/simulated/shuttle/wall))
						continue
					else if(istype(thisturf, /turf/unsimulated/wall))
						continue
					turfs += thisturf
				var/turf/target_turf = pick(turfs)

				//MUH 6 QUADRILLION WINDOWS
				//rampage along a path to get to it, in the blink of an eye
				var/turf/next_turf = get_step_towards(src, target_turf)
				var/num_turfs = get_dist(src,target_turf)
				while(get_turf(src) != target_turf && num_turfs > 0)
					for(var/obj/structure/window/W in next_turf)
						spawn(5) W.destroy()
					for(var/obj/structure/table/O in next_turf)
						spawn(5) O.ex_act(1)
					for(var/obj/structure/grille/G in next_turf)
						spawn(5) G.ex_act(1)
					for(var/obj/machinery/door/D in next_turf)
						spawn(5) D.open()
					if(!next_turf.CanPass(src, next_turf))
						break
					src.loc = next_turf
					src.dir = get_dir(src, target)
					next_turf = get_step(src, get_dir(next_turf,target_turf))
					num_turfs--

		//if(!istype(src.loc, /turf)) // Is SCP-173 in a container/closet/pod/tray etc? Well fuck it

//	else if(G)
//		//we can't move while observed, so we can't effectively strangle any more //since victim is observer this means no strangling
//		//our grip is still rock solid, but the victim has a chance to escape
//		G.affecting << "\red You suddenly feel the grip around your neck being loosened!"
//		visible_message("\red [src] suddenly loosens it's grip due to being observed!")
//		G.state = GRAB_AGGRESSIVE

/mob/living/simple_animal/sculpture/attackby(var/obj/item/O as obj, var/mob/user as mob)
	..()

/mob/living/simple_animal/sculpture/Topic(href, href_list)
	..()

/mob/living/simple_animal/sculpture/Bump(atom/movable/AM as mob, yes)
	if(!G)
		GrabMob(AM)

/mob/living/simple_animal/sculpture/Bumped(atom/movable/AM as mob, yes)
	if(!G)
		GrabMob(AM)

/mob/living/simple_animal/sculpture/ex_act(var/severity)
	//nothing
#define PHYSICAL_HARM "physical"
#define BREATH_HARM "oxy"

/mob/living/carbon
	var/agony = 0
	var/agony_max = 500
	COOLDOWN_DECLARE(time_till_agony_process)

/mob/living/carbon/human/take_overall_damage(brute, burn, stamina, updating_health, required_bodytype)
	. = ..()
	if(brute || burn)
		take_agony(brute + burn, PHYSICAL_HARM)

	if((brute + burn) >= 10)
		harm_organs(brute + burn)

/mob/living/carbon/human/adjustBruteLoss(amount, updating_health, forced, required_bodytype)
	. = ..()
	if(amount > 0)
		take_agony(amount, PHYSICAL_HARM)

/mob/living/carbon/human/adjustFireLoss(amount, updating_health, forced, required_bodytype)
	. = ..()
	if(amount > 0)
		take_agony(amount, PHYSICAL_HARM)

/mob/living/carbon/human/adjustOxyLoss(amount, updating_health, forced, required_biotype, required_respiration_type)
	. = ..()
	if(amount > 0)
		take_agony(amount, BREATH_HARM)

/mob/living/carbon/human/apply_damage(damage, damagetype, def_zone, blocked, mob/living/carbon/human/H, forced, spread_damage, wound_bonus, bare_wound_bonus, sharpness, attack_direction)
	. = ..()
	var/agony = damage
	if(damagetype == OXY)
		agony *= 0.5
	if(damagetype == OXY || damagetype == BRUTE || damagetype == BURN)
		H.take_agony(agony)

/mob/living/carbon/human/Life(delta_time, times_fired)
	. = ..()
	process_agony()

/mob/living/carbon/human/proc/take_agony(damage, type)
	if(stat == DEAD)
		return

	if(type == BREATH_HARM)
		damage *= 0.5

	agony = clamp(agony, 0, agony_max)

/mob/living/carbon/human/proc/harm_organs(damage_taken)
	for(var/obj/item/organ/internal/internal_organ as anything in organs)
		if(prob(damage_taken * 2))
			internal_organ.apply_organ_damage(damage_taken)

/mob/living/carbon/human/proc/process_agony()
	if(stat == DEAD)
		return

	if(!COOLDOWN_FINISHED(src, time_till_agony_process))
		return

	COOLDOWN_START(src, time_till_agony_process, 3 SECONDS)

	take_agony(-3)

	for(var/datum/reagent/painkiller as anything in get_wounded_bodyparts())
		for(var/datum/wound/ouchie as anything in wounded_part.wounds)
			take_agony(1)

	for(var/obj/item/bodypart/wounded_part as anything in get_wounded_bodyparts())
		for(var/datum/wound/ouchie as anything in wounded_part.wounds)
			take_agony(1)

	for(var/obj/item/organ/internal/internal_organ as anything in organs)
		if(internal_organ.damage > 75)
			take_agony(2.5)
		else if(internal_organ.damage > 50)
			take_agony(2)
		else if(internal_organ.damage > 25)
			take_agony(1.25)
		else if(internal_organ.damage > 0)
			take_agony(0.5)


	if((agony >= 250) && prob(agony / 75))
		var/datum/disease/heart_disease = new /datum/disease/heart_failure()
		ForceContractDisease(heart_disease, FALSE, TRUE)
		to_chat(src, span_warning("You feel something in your chest sieze up through your pain!"))
		return

	if(prob(agony / 25))
		Knockdown(10 SECONDS)
		Paralyze(10 SECONDS)
		to_chat(src, span_warning("You collapse from the pain! Oh please, just make it end!"))
		return

	if(prob(agony / 15))
		drop_all_held_items()
		to_chat(src, span_warning("You drop what you were holding, crying out in pain!"))
		emote("scream")
		return

	if(prob(50))
		return

	if(agony >= 300)
		to_chat(src, span_warning("Your body feels like it's on fire, you can barely see through the haze of pain!"))
		add_mood_event("agony", /datum/mood_event/agony/mortis)
		return

	if(agony >= 100)
		to_chat(src, span_warning("Your body aches terribly! It's hard to focus through the horrible, horrible pain!"))
		add_mood_event("agony", /datum/mood_event/agony/severe)
		return

	if(agony >= 50)
		to_chat(src, span_warning("Your body stings with pain. It's not too bad, but it still hurts."))
		add_mood_event("agony", /datum/mood_event/agony)
		return

	if(agony >= 20)
		to_chat(src, span_warning("Your body stings with pain. It's not too bad, but it still hurts."))
		add_mood_event("agony", /datum/mood_event/agony/minor)
		return

	if(agony)
		to_chat(src, span_warning("You feel a light throb of pain, but you're okay."))
		add_mood_event("agony", /datum/mood_event/agony/negligible)
		return


/datum/mood_event/agony
	description = "I'm in quite a bit of pain!"
	mood_change = -4

/datum/mood_event/agony/negligible
	description = "I'm in a tiny bit of pain, but nothing I haven't felt before."
	mood_change = -1

/datum/mood_event/agony/minor
	description = "I feel a dull pain, but it's not too bad."
	mood_change = -2

/datum/mood_event/agony/severe
	description = "Everything hurts horribly..."
	mood_change = -8

/datum/mood_event/agony/mortis
	description = "AAAAAAAAAAAAAH FUCK"
	mood_change = -20


// And now: numbers pulled out of my ass

/datum/reagent/medicine/morphine/on_mob_life(mob/living/carbon/affected_mob)
	affected_mob.agony -= 25
	..()

/datum/reagent/determination/on_mob_life(mob/living/carbon/M)
	M.agony -= 7.5
	..()

/datum/reagent/medicine/mine_salve/on_mob_life(mob/living/carbon/affected_mob)
	affected_mob.agony -= 20
	..()

/datum/reagent/consumable/ethanol/on_mob_life(mob/living/carbon/M)
	M.agony -= 2.5
	..()

/datum/reagent/consumable/ethanol/painkiller/on_mob_life(mob/living/carbon/M)
	M.agony -= 7.5
	..()

/datum/reagent/medicine/granibitaluri/on_mob_life(mob/living/carbon/affected_mob)
	affected_mob.agony -= 2.5
	..()

/datum/reagent/drug/opium/on_mob_life(mob/living/carbon/M)
	M.agony -= 3
	..()

/datum/reagent/drug/opium/heroin/on_mob_life(mob/living/carbon/M)
	M.agony -= 2
	..()

/datum/reagent/drug/cocaine/on_mob_life(mob/living/carbon/M)
	M.agony -= 8
	..()

/datum/reagent/drug/pcp/on_mob_life(mob/living/carbon/M)
	M.agony -= 30
	..()

#undef PHYSICAL_HARM
#undef BREATH_HARM

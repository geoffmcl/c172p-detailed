##########################################
# Ground Detection
##########################################

# Do terrain modelling ourselves.
#setprop("sim/fdm/surface/override-level", 1);

var terrain_survol_loop = func {
  var lat = getprop("/position/latitude-deg");
  var lon = getprop("/position/longitude-deg");

  var info = geodinfo(lat, lon);
  if (info != nil) {
    if (info[1] != nil){
      if (info[1].solid !=nil)
        setprop("/environment/terrain-type",info[1].solid);
      if (info[1].load_resistance !=nil)
        setprop("/environment/terrain-load-resistance",info[1].load_resistance);
      if (info[1].friction_factor !=nil)
        setprop("/environment/terrain-friction-factor",info[1].friction_factor);
      if (info[1].bumpiness !=nil)
        setprop("/environment/terrain-bumpiness",info[1].bumpiness);
      if (info[1].rolling_friction !=nil)
        setprop("/environment/terrain-rolling-friction",info[1].rolling_friction);
      if (info[1].names !=nil)
        setprop("/environment/terrain-names",info[1].names[0]);
    }         
  }else{
    setprop("/environment/terrain",1);
    setprop("/environment/terrain-load-resistance",1e+30);
    setprop("/environment/terrain-friction-factor",1.05);
    setprop("/environment/terrain-bumpiness",0);
    setprop("/environment/terrain-rolling-friction",0.02);
  }

  if(!getprop("sim/freeze/replay-state") and !getprop("/environment/terrain-type") and getprop("/position/altitude-agl-ft") < 3.0){
    setprop("sim/messages/copilot", "You are on water !");
    setprop("sim/freeze/clock", 1);
    setprop("sim/freeze/master", 1);
    setprop("sim/crashed", 1);
  }

}

###########################################
# use this loop for any system that requires
# monitoring and possesses no loop of its own
############################################
var check_systems_status = func {

	#check for volume shadow version and ALS requirements 
	var p = getprop("/sim/rendering/shadow-volume");
	if (p) {
		if (!c172p.check_eligibility()) {
			setprop("/sim/rendering/shadow-volume", 0);
		} 
	}
}

var reset_system = func {

    if (getprop("/fdm/jsbsim/complex"))
    {
        setprop("/controls/engines/engine/magnetos", 0);
        setprop("/controls/engines/engine/throttle", 0);
        setprop("/controls/engines/engine/mixture", 0);
        setprop("/controls/engines/engine/master-bat", 0);
        setprop("/controls/engines/engine/master-alt", 0);
        setprop("/controls/switches/master-avionics", 0);
        setprop("/controls/lighting/nav-lights", 0);
        setprop("/controls/lighting/strobe", 0);
        setprop("/controls/lighting/beacon", 0);
        setprop("/consumables/fuel/tank[0]/selected", 0);
        setprop("/consumables/fuel/tank[1]/selected", 0);
    }
    else
        c172p.autostart();

    # These properties are aliased to MP properties in /sim/multiplay/generic/.
    # This aliasing seems to work in both ways, because the two properties below
    # appear to receive the random values from the MP properties during initialization.
    # Therefore, override these random values with the proper values we want.
    props.globals.getNode("/fdm/jsbsim/crash", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/contact/unit[4]/broken", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/contact/unit[5]/broken", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/gear/unit[0]/broken", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/gear/unit[1]/broken", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/gear/unit[2]/broken", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/wing-damage/left-wing", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/wing-damage/right-wing", 0).setBoolValue(0);
	props.globals.getNode("/fdm/jsbsim/left-pontoon/damaged", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/left-pontoon/broken", 0).setBoolValue(0);
	props.globals.getNode("/fdm/jsbsim/right-pontoon/damaged", 0).setBoolValue(0);
    props.globals.getNode("/fdm/jsbsim/right-pontoon/broken", 0).setBoolValue(0);

	setprop("/fdm/jsbsim/propulsion/tank[2]/priority", 1);
	setprop("/fdm/jsbsim/contact/unit[4]/z-position", 50);
	setprop("/fdm/jsbsim/contact/unit[5]/z-position", 50);
	if (getprop("/fdm/jsbsim/bushkit") == 3)
	{
		setprop("/fdm/jsbsim/contact/unit[13]/z-position", -60);
		setprop("/fdm/jsbsim/contact/unit[14]/z-position", -60);
		setprop("/fdm/jsbsim/contact/unit[15]/z-position", -25);
		setprop("/fdm/jsbsim/contact/unit[16]/z-position", -25);
	}
	else
	{
		setprop("/fdm/jsbsim/contact/unit[13]/z-position", 0);
		setprop("/fdm/jsbsim/contact/unit[14]/z-position", 0);
		setprop("/fdm/jsbsim/contact/unit[15]/z-position", 0);
		setprop("/fdm/jsbsim/contact/unit[16]/z-position", 0);
	}

	var p = getprop("fdm/jsbsim/bushkit");
	setprop("/sim/model/c172p/bushkit_flag_0",0);
	setprop("/sim/model/c172p/bushkit_flag_1",0);
	setprop("/sim/model/c172p/bushkit_flag_2",0);
	setprop("/sim/model/c172p/bushkit_flag_3",0);
	setprop("/sim/model/c172p/bushkit_flag_4",0);
	if (p == 0) { setprop("/sim/model/c172p/bushkit_flag_0",1); }
	if (p == 1) { setprop("/sim/model/c172p/bushkit_flag_1",1); }
	if (p == 2) { setprop("/sim/model/c172p/bushkit_flag_2",1); }
	if (p == 3) { setprop("/sim/model/c172p/bushkit_flag_3",1); }
	if (p == 4) { setprop("/sim/model/c172p/bushkit_flag_4",1); }
}

############################################
# Global loop function
# If you need to run nasal as loop, add it in this function
############################################
global_system_loop = func{

  # terrain_survol_loop was incorporated during damage system creation. 
  # "Unimplemented" crash detection system requires this self terrain modelling (I think)
  # If we end up not using it, then we can remove it.
  #terrain_survol_loop();
  c172p.physics_loop();
  c172p.weather_effects_loop();
  check_systems_status();

}

##########################################
# SetListerner must be at the end of this file
##########################################
#setlistener("/sim/signals/fdm-initialized", func{
#  setprop("/environment/terrain-type",1);
#  setprop("/environment/terrain-load-resistance",1e+30);
#  setprop("/environment/terrain-friction-factor",1.05);
#  setprop("/environment/terrain-bumpiness",0);
#  setprop("/environment/terrain-rolling-friction",0.02);
#});

var nasalInit = setlistener("/sim/signals/fdm-initialized", func{
    reset_system();
    var c172_timer = maketimer(0.25, func{global_system_loop()});
    c172_timer.start();
});

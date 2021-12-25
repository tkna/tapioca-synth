Tapioca {
    var <>x, <>amp, <>synth, <>env, <>state, <>start_time, <>group, <>selected;
    var <>attackTime, <>decayTime, <>sustainLevel, <>releaseTime;

    *new { |x, group, attackTime, decayTime, sustainLevel, releaseTime, standby = false|
        ^super.new.init(x, group, attackTime, decayTime, sustainLevel, releaseTime, standby);
    }

    init { |x, group, attackTime, decayTime, sustainLevel, releaseTime, standby|
        this.x = x;
        this.amp = 0;
        this.group = group;
        this.attackTime = attackTime;
        this.decayTime = decayTime;
        this.sustainLevel = sustainLevel;
        this.releaseTime = releaseTime;

        if((sustainLevel == 0),
            {this.env = Env.perc(attackTime, decayTime)},
            {this.env = Env.adsr(attackTime, decayTime, sustainLevel, releaseTime, curve:-2)}
        );

        if(standby, {
          this.state = "standby";
          this.selected = true;
        },{
          this.play;
          this.selected = false;
        });
    }

    play {
    	var lfo_mode;
        synth = Synth(\sine, [\out, 0, \freq, x.linexp(0, 600, 80, 4000), \amp, 1.0, \env, env]);
        start_time = Main.elapsedTime;
        state = "attack";
    }

    changeSustainLevel {|amp_new|
        amp = amp_new;
        synth.set(\mode, 1);
        synth.set(\amp, amp);
        state = "manual";

        sustainLevel = amp_new;
        env = Env.adsr(attackTime, decayTime, sustainLevel, releaseTime);
        synth.set(\env, env);
    }

    setSustainLevelWithCurrentAmp {
        env = Env.adsr(attackTime, decayTime, amp, releaseTime);
    }

    refresh {
    	if((state != "manual") && ((state == "attack") || (state == "release") ) ) {
    		var t = Main.elapsedTime - start_time;
			if (state == "attack") {
				if (t <= (attackTime + decayTime)) {
					amp = env.at(t);
				};
				if (t > (attackTime + decayTime)) {
					if(sustainLevel != 0) {
						amp = sustainLevel;
						state = "sustain";
					};
					if(sustainLevel == 0) {
						amp = 0;
						state = "finished";
					};
				};
			};
			if (state == "release") {
				if (t <= releaseTime) {
					amp = env.at(t + attackTime + decayTime);
				};
				if (t > releaseTime) {
					amp = 0;
					state = "finished";
				};
			};
		};
	}
}
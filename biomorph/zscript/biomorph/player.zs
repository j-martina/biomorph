class BIO_Player : DoomPlayer
{
	Default
	{
		Tag "$BIO_MODTITLE";
		Species 'Player';
		BloodColor 'Cyan';

		Player.DisplayName "$BIO_MODTITLE";
		Player.SoundClass 'biomorph';

		Player.StartItem 'BIO_Slot3Ammo', 0;
		Player.StartItem 'BIO_Slot4Ammo', 0;
		Player.StartItem 'BIO_Slot5Ammo', 0;
		Player.StartItem 'BIO_Slot67Ammo', 0;

		Player.StartItem 'BIO_Melee';
		Player.StartItem 'BIO_Pistol';
	}

	/// Inversely proportional to added movement inertia;
	/// lower number means less slippery.
	const DECEL_MULT = 0.85;

	override void Tick()
	{
		super.Tick();

		// Code below courtesy of Nash Muhandes
		// https://forum.zdoom.org/viewtopic.php?f=105&t=35761

		if (self.pos.Z ~== self.floorZ || self.bOnMObj)
		{
			// Bump up the player's speed to compensate for the deceleration
			// TODO (NASH): math here is shit and wrong, please fix
			double s = 1.0 + (1.0 - DECEL_MULT);
			self.speed = s * 2.2;

			// Decelerate the player, if not in pain
			self.vel.X *= DECEL_MULT;
			self.vel.Y *= DECEL_MULT;

			// Make the view bobbing match the player's movement
			self.viewBob = DECEL_MULT;
		}

		if (!self.player.onGround || self.vel.Length() < 0.1)
			return;

		// Periodic footstep sounds. Math below courtesy of Marrub
		// See DoomRL_Arsenal.pk3/scripts/DRLALIB_Misc.acs, "RLGetStepSpeed"

		float v = (Abs(self.vel.X), Abs(self.vel.Y)).Length();
		float mul = Clamp(1.0 - (v / 24.0), 0.35, 1.0);
		let interval = int(10.0 * (mul + 0.6));

		if ((Level.MapTime % interval) != 0)
			return;

		self.A_StartSound("bio/pawn/footstep/normal", CHAN_AUTO);
	}

	override void PreTravelled()
	{
		super.PreTravelled();

		// Suppress death exists if the user prefers to do so
		// This block courtesy of Marisa the Magician
		// See SWWMGZ's counterpart: `Demolitionist::PreTravelled`
		// Used under the MIT License
		// https://github.com/OrdinaryMagician/swwmgz_m/blob/master/LICENSE.code
		if ((self.player != null) &&
			(self.player.PlayerState == PST_DEAD))
		{
			self.player.Resurrect();

			self.player.DamageCount = 0;
			self.player.BonusCount = 0;
			self.player.PoisonCount = 0;
			self.roll = 0;

			if (self.special1 > 2)
				self.special1 = 0;
		}
	}
}

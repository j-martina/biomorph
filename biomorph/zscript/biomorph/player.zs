class biom_Player : DoomPlayer
{
	protected biom_PlayerData data;

	uint8 weaponCapacity;
	property WeaponCapacity: weaponCapacity;

	private biom_WeaponFamily weaponsFound;

	Default
	{
		Tag "$BIOM_PAWN_DISPLAYNAME";
		Species 'Player';
		BloodColor 'Cyan';

		Player.DisplayName "$BIOM_PAWN_DISPLAYNAME";
		Player.FallingScreamSpeed 20.0, 40.0;
		Player.SoundClass 'biomorph';
		Player.ViewHeight 48.0;

		Player.StartItem 'biom_Slot3Ammo', 0;
		Player.StartItem 'biom_Slot4Ammo', 0;
		Player.StartItem 'biom_Slot5Ammo', 0;
		Player.StartItem 'biom_Slot67Ammo', 0;

		Player.StartItem 'biom_ServicePistol';
		Player.StartItem 'biom_Unarmed';

		biom_Player.WeaponCapacity 8;
	}

	/// Inversely proportional to added movement inertia;
	/// lower number means less slippery.
	const DECEL_MULT = 0.85;

	override void PostBeginPlay()
	{
		super.PostBeginPlay();

		let globals = biom_Global.Get();

		// This can happen if the player dies and loads a saved game.
		// Between starting and finishing the load, the engine is briefly in
		// an incoherent state and this branch happens.
		if (globals == null)
			return;

		self.data = globals.FindPlayerData(self.player);
		self.weaponsFound = BIOM_WEAPFAM_SIDEARM;

		Biomorph.Assert(
			self.data != null,
			"Failed to get pawn data in `biom_Player::PostBeginPlay`."
		);
	}

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

		self.A_StartSound("biom/pawn/footstep/normal", CHAN_AUTO);
	}

	override void PreTravelled()
	{
		super.PreTravelled();

		// Suppress death exists if the user prefers to do so.
		// This block below is courtesy of Marisa the Magician.
		// See SWWMGZ's counterpart: `Demolitionist::PreTravelled`.
		// Used under the MIT License.
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

	override void ClearInventory()
	{
		super.ClearInventory();

		for (int i = 0; i < self.data.weapons.Size(); ++i)
			self.TakeInventory(self.data.weapons[i], 1);

		self.weaponsFound = BIOM_WEAPFAM_SIDEARM;

		let bArmor = BasicArmor(self.FindInventory('BasicArmor'));
		bArmor.savePercent = 0;
		bArmor.armorType = 'None';
		textureID nullTexID;
		nullTexID.SetNull();
		bArmor.icon = nullTexID;
	}

	override void GiveDefaultInventory()
	{
		super.GiveDefaultInventory();

		if (biom_Utils.Valiant())
		{
			let s4 = Ammo(self.FindInventory('biom_Slot4Ammo'));
			s4.maxAmount = Max(s4.maxAmount, 300);
			s4.backpackMaxAmount = Max(s4.backpackMaxAmount, 600);
		}
	}

	void OnWeaponFound(biom_WeaponFamily wf)
	{
		self.weaponsFound |= wf;
	}

	/// Called in order to undo the effects of all applied alterants.
	void Reset()
	{
		self.bDontThrust = self.default.bDontThrust;
		self.bCantSeek = self.default.bCantSeek;

		self.maxHealth = self.default.maxHealth;
		self.bonusHealth = self.default.bonusHealth;
		self.stamina = self.default.stamina;

		self.forwardMove1 = self.default.forwardMove1;
		self.forwardMove2 = self.default.forwardMove2;
		self.sideMove1 = self.default.sideMove1;
		self.sideMove2 = self.default.sideMove2;
		self.jumpZ = self.default.jumpZ;
		self.friction = self.default.friction;
		self.gravity = self.default.gravity;
		self.mass = self.default.mass;
		self.maxStepHeight = self.default.maxStepHeight;
		self.maxSlopeSteepness = self.default.maxSlopeSteepness;

		self.useRange = self.default.useRange;
		self.airCapacity = self.default.airCapacity;
		self.radiusDamageFactor = self.default.radiusDamageFactor;
		self.selfDamageFactor = self.default.selfDamageFactor;

		for (int i = 0; i < self.data.weaponData.Size(); ++i)
			self.data.weaponData[i].Reset();
	}

	readonly<biom_PlayerData> GetData() const
	{
		return self.data.AsConst();
	}

	biom_PlayerData GetDataMut()
	{
		return self.data;
	}

	biom_WeaponFamily GetWeaponsFound() const
	{
		return self.weaponsFound;
	}

	/// The status bar needs `GetData` to be `const` but weapon attach-to-owner
	/// code runs before `EventHandler::NewGame` and `PlayerPawn::PostBeginPlay`,
	/// so it needs special handling.
	readonly<biom_PlayerData> GetOrInitData()
	{
		if (self.data == null)
		{
			let globals = biom_Global.Get();

			// See `PostBeginPlay` for details on this.
			if (globals == null)
				return null;

			self.data = globals.FindPlayerData(self.player);
		}

		return self.data.AsConst();
	}

	readonly<biom_Player> AsConst() const
	{
		return self;
	}
}

class biom_PlayerPistolStart : biom_Player
{
	Default
	{
		Player.DisplayName "$BIOM_PAWN_DISPLAYNAME_LAPSING";
	}

	override void PreTravelled()
	{
		super.PreTravelled();
		self.ClearInventory();
		self.GiveDefaultInventory();
		self.A_SetHealth(self.GetMaxHealth());
	}
}

class biom_PlayerResetItem : Inventory
{
	bool primed;

	Default
	{
		-COUNTITEM
		+DONTGIB
		+FLOATBOB
		+INVENTORY.INVBAR

		Tag "$BIOM_PLAYERRESETITEM_TAG";
		Height 16.0;
		Radius 20.0;

		Inventory.Amount 1;
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "$BIOM_PLAYERRESETITEM_PKUP";
		Inventory.RestrictedTo 'biom_Player';
		Inventory.UseSound "";
	}

	States
	{
	Spawn:
		ANTG A 6;
		#### B 6 bright light("biom_PlayerResetItem");
		loop;
	}

	final override bool Use(bool pickup)
	{
		let pawn = biom_Player(self.owner);

		if (!self.primed)
		{
			string prompt = String.Format("$BIOM_PLAYERRESETITEM_CONFIRM");
			pawn.A_Print(prompt, 3.0);
			pawn.A_StartSound("biom/ui/beep", CHAN_AUTO);
			self.primed = true;
			return false;
		}
		else
		{
			pawn.A_Print("", 0.0); // Flush confirmation prompt off the screen.
			self.primed = false;
			pawn.Reset();
			return true;
		}
	}
}

class biom_PlayerResetDisarmer : Thinker
{
	private biom_PlayerResetItem toDisarm;
	private uint lifetime;

	static biom_PlayerResetDisarmer Create(biom_PlayerResetItem toDisarm)
	{
		let ret = new('biom_PlayerResetDisarmer');
		ret.toDisarm = toDisarm;
		return ret;
	}

	final override void Tick()
	{
		super.Tick();

		if (self.bDestroyed)
			return;

		self.lifetime += 1;

		if (self.lifetime >= (TICRATE * 3))
		{
			toDisarm.primed = false;

			if (!self.bDestroyed)
				self.Destroy();

			return;
		}
	}
}

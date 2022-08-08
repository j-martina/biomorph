// Determines what vanilla weapon a Biomorph weapon is intended to replace.
enum BIO_WeaponSpawnCategory : uint8
{
	BIO_WSCAT_SHOTGUN,
	BIO_WSCAT_CHAINGUN,
	BIO_WSCAT_SSG,
	BIO_WSCAT_RLAUNCHER,
	BIO_WSCAT_PLASRIFLE,
	BIO_WSCAT_BFG9000,
	BIO_WSCAT_CHAINSAW,
	BIO_WSCAT_PISTOL,
	__BIO_WSCAT_COUNT__
}

// Without this, there's no way for outside code to know that a weapon
// which isn't explicitly `BIO_Fist` is another fist-type weapon.
// Will probably expand this as technical needs become clearer.
enum BIO_WeaponFamily : uint8
{
	BIO_WEAPFAM_NONE,
	BIO_WEAPFAM_FIST
}

// Prevent one button push from invoking a weapon's special functor multiple times.
class BIO_WeaponSpecialCooldown : Powerup
{
	Default
	{
		Powerup.Duration 15;
		+INVENTORY.UNTOSSABLE
	}
}

class BIO_Magazine : Ammo
{
	Default
	{
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.IGNORESKILL

		Inventory.MaxAmount uint16.MAX;
		Inventory.PickupMessage
			"If you see this message, please report a bug to RatCircus.";
	}

	// This class can't be abstract because it would cause a VM abort if the
	// player invoked the `give all` CCMD
	// Why doesn't this command check for abstract classes?
	// I assume there's an underlying technical reason
	// To work around this, just pretend the base class doesn't exist

	final override void BeginPlay()
	{
		super.BeginPlay();

		if (GetClass() == 'BIO_Magazine')
			Destroy();
	}

	final override void AttachToOwner(Actor other)
	{
		if (GetClass() == 'BIO_Magazine')
			return;
		else
			super.AttachToOwner(other);
	}

	final override bool CanPickup(Actor _)
	{
		return GetClass() != 'BIO_Magazine';
	}
}

class BIO_MagazineETM : BIO_Magazine
{
	meta class<BIO_EnergyToMatterPowerup> PowerupType;
	property PowerupType: PowerupType;

	Default
	{
		Inventory.MaxAmount 0;
	}
}

class BIO_EnergyToMatterPowerup : Powerup abstract
{
	meta int CellCost;
	property CellCost: CellCost;

	Default
	{
		+INVENTORY.UNTOSSABLE
		Powerup.Duration -3;
		BIO_EnergyToMatterPowerup.CellCost 5;
	}
}

// Used to provide semantic meaning to an STG. If a constant isn't here,
// you don't need to worry that it may need to be applied.
enum BIO_StateTimeGroupDesignation : uint8
{
	BIO_STGD_NONE,
	BIO_STGD_COOLDOWN,
	BIO_STGD_SPOOLUP,
	BIO_STGD_FIRESPOOLED,
	BIO_STGD_SPOOLDOWN
}

enum BIO_StateTimeGroupFlags : uint8
{
	BIO_STGF_NONE = 0,
	// If set, this STG isn't shown to the user anywhere.
	BIO_STGF_HIDDEN = 1 << 0,
	// Changes how a fire-time group is presented to the user
	// ("attack time" rather than "fire time").
	BIO_STGF_MELEE = 1 << 1
}

class BIO_StateTimeGroup
{
	BIO_StateTimeGroupDesignation Designation;
	BIO_StateTimeGroupFlags Flags;
	string Tag;
	Array<uint8> Times, Minimums;

	uint TotalTime() const
	{
		uint ret = 0;

		for (uint i = 0; i < Times.Size(); i++)
			ret += Times[i];

		return ret;
	}

	// Used for checking if fire/reload time modifications are possible,
	// and the allowances on any reductions made. Returns a positive number.
	uint PossibleReduction() const
	{
		uint ret = 0;

		for (uint i = 0; i < Times.Size(); i++)
			ret += Max(Times[i] - Minimums[i], 0);

		return ret;
	}

	uint MinTotalTime() const
	{
		uint ret = 0;

		for (uint i = 0; i < Times.Size(); i++)
			ret += Minimums[i];

		return ret;
	}

	bool IsAuxiliary() const
	{
		return Designation > BIO_STGD_NONE;
	}

	bool IsHidden() const
	{
		return Flags & BIO_STGF_HIDDEN;
	}

	void Modify(int modifier)
	{
		if (modifier == 0)
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Illegal time modifier of 0 given to state time group %s.", Tag);
			return;
		}

		let pr = PossibleReduction();

		uint e = Abs(modifier);

		for (uint i = 0; i < e; i++)
		{
			if (pr <= 0)
				break;

			uint idx = 0, minOrMax = 0;

			if (modifier > 0)
			{
				[minOrMax, idx] = BIO_Utils.Uint8ArrayMin(Times);
				pr++;
			}
			else
			{
				[minOrMax, idx] = BIO_Utils.Uint8ArrayMax(Times);
				pr--;
			}

			Times[idx] = modifier > 0 ? Times[idx] + 1 : Times[idx] - 1;
		}
	}

	void SetTotalTime(uint newTotal)
	{
		Modify(-(int(TotalTime()) - int(newTotal)));
	}

	void SetToMinTotalTime()
	{
		for (uint i = 0; i < Times.Size(); i++)
			Times[i] = Minimums[i];
	}

	private void Populate(state base)
	{
		Array<state> done;

		for (state s = base; s.InStateSequence(base); s = s.NextState)
		{
			if (done.Find(s) != done.Size())
				return; // Infinite loop protection

			if (s.Tics == 0)
				continue; // `TNT1 A 0` and the like

			done.Push(s);
			Times.Push(s.Tics);
			int min;

			// States marked `Fast` are allowed to have their tic time set  
			// to 0, effectively eliminating them from the state sequence
			if (s.bFast)
				min = 0;
			// States marked `Slow` are kept immutable
			else if (s.bSlow)
				min = s.Tics;
			else
				min = 1;

			Minimums.Push(min);
		}
	}

	private void RangePopulate(state from, state to)
	{
		for (state s = from; s.InStateSequence(from); s = s.NextState)
		{
			if (s.DistanceTo(to) <= 0)
				return;

			if (s.Tics == 0)
				continue; // `TNT1 A 0` and the like

			Times.Push(s.Tics);
			int min;

			// States marked `Fast` are allowed to have their tic time set  
			// to 0, effectively eliminating them from the state sequence
			if (s.bFast)
				min = 0;
			// States marked `Slow` are kept immutable
			else if (s.bSlow)
				min = s.Tics;
			else
				min = 1;

			Minimums.Push(min);
		}
	}

	string GetTagAsQualifier(string parenthClr = "\c[White]") const
	{
		if (Tag.Length() < 1)
			return "";
		else
			return String.Format("%s(\c[Yellow]%s%s)",
				parenthClr, StringTable.Localize(Tag), parenthClr);
	}

	// Add the tic times from all states in a contiguous sequence from `basis`
	// to this group. Beware that this will skip labels, and treats
	// `Goto MyState; MyState:` as contiguous.
	static BIO_StateTimeGroup FromState(
		state basis,
		string tag = "",
		BIO_StateTimeGroupDesignation designation = BIO_STGD_NONE,
		BIO_StateTimeGroupFlags flags = BIO_STGF_NONE
	)
	{
		let ret = new('BIO_StateTimeGroup');
		ret.Tag = Tag;
		ret.Designation = designation;
		ret.Flags = flags;
		ret.Populate(basis);
		return ret;
	}

	// Same as `FromState()`, but stops adding times upon arriving at `end`.
	static BIO_StateTimeGroup FromStateRange(
		state start,
		state end,
		string tag = "",
		BIO_StateTimeGroupDesignation designation = BIO_STGD_NONE,
		BIO_StateTimeGroupFlags flags = BIO_STGF_NONE
	)
	{
		let ret = new('BIO_StateTimeGroup');
		ret.Tag = Tag;
		ret.Designation = designation;
		ret.Flags = flags;
		ret.RangePopulate(start, end);
		return ret;
	}

	static BIO_StateTimeGroup FromStates(
		Array<state> stateptrs,
		string tag = "",
		BIO_StateTimeGroupDesignation designation = BIO_STGD_NONE,
		BIO_StateTimeGroupFlags flags = BIO_STGF_NONE
	)
	{
		let ret = new('BIO_StateTimeGroup');
		ret.Tag = Tag;
		ret.Designation = designation;
		ret.Flags = flags;

		for (uint i = 0; i < stateptrs.Size(); i++)
			ret.Populate(stateptrs[i]);

		return ret;
	}
}

// Affixes are how modifiers apply behaviours to weapons rather than stat changes.
class BIO_WeaponAffix play abstract
{
	// Called by `DoPickupSpecial()`.
	virtual void OnPickup(BIO_Weapon weap) {}
	virtual void OnTick(BIO_Weapon weap) {}

	// Called by the `BIO_Weapon` functions of the same name.
	virtual void OnSelect(BIO_Weapon weap) {}
	virtual void OnDeselect(BIO_Weapon weap) {}

	// Called before magazine pointers are invalidated.
	virtual void OnDrop(BIO_Weapon weap, BIO_Player dropper) {}

	// Only gets called if enough ammo is present.
	virtual void BeforeAmmoDeplete(BIO_Weapon weap,
		in out int ammoUse, bool altFire) {}

	// Called by `A_BIO_LoadMag()`, right after all calculations are finished,
	// and directly before taking player reserves and increasing magazine amount.
	virtual void OnMagLoad(BIO_Weapon weap, bool secondary,
		in out int toDraw, in out int toLoad) {}

	// Modify only the shot count or the critical flag here;
	// everything else gets overwritten afterwards.
	virtual void BeforeAllShots(BIO_Weapon weap, in out BIO_ShotData shotData) {}

	// Modifying `ShotCount` here does nothing, since it is overwritten afterwards.
	virtual void BeforeEachShot(BIO_Weapon weap, in out BIO_ShotData shotData) {}

	virtual void OnSlowProjectileFired(BIO_Weapon weap, BIO_Projectile proj) {}
	virtual void OnFastProjectileFired(BIO_Weapon weap, BIO_FastProjectile proj) {}
	virtual void OnPuffFired(BIO_Weapon weap, BIO_Puff puff) {}

	// Be aware that this is called on the readied weapon, which may not be the
	// weapon which was actually used to cause the kill. Plan accordingly.
	virtual void OnKill(BIO_Weapon weap, Actor killed, Actor inflictor) {}

	virtual ui void RenderOverlay(BIO_RenderContext context) const {}

	abstract string Description(readOnly<BIO_Weapon> weap) const;
}

class BIO_WeaponSpecialFunctor play abstract
{
	abstract state Invoke(BIO_Weapon weap) const;
}

// Replacing weapons was previously done at the spawn-event level, but this
// left certain DEHACKED pickups slip past until they got touched, giving the
// player a weapon they were never supposed to even encounter (see the
// Super Shotgun in Ancient Aliens MAP20 as an example).
class BIO_WeaponReplacer : BIO_IntangibleActor abstract
{
	meta BIO_WeaponSpawnCategory SpawnCategory;
	property SpawnCategory: SpawnCategory;
}

class BIO_WeaponReplacer_Shotgun : BIO_WeaponReplacer replaces Shotgun
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_SHOTGUN;
	}
}

class BIO_WeaponReplacer_Chaingun : BIO_WeaponReplacer replaces Chaingun
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_CHAINGUN;
	}
}

class BIO_WeaponReplacer_SSG : BIO_WeaponReplacer replaces SuperShotgun
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_SSG;
	}
}

class BIO_WeaponReplacer_RocketLauncher : BIO_WeaponReplacer replaces RocketLauncher
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_RLAUNCHER;
	}
}

class BIO_WeaponReplacer_PlasRifle : BIO_WeaponReplacer replaces PlasmaRifle
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_PLASRIFLE;
	}
}

class BIO_WeaponReplacer_BFG9000 : BIO_WeaponReplacer replaces BFG9000
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_BFG9000;
	}
}

class BIO_WeaponReplacer_Chainsaw : BIO_WeaponReplacer replaces Chainsaw
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_CHAINSAW;
	}
}

class BIO_WeaponReplacer_Pistol : BIO_WeaponReplacer replaces Pistol
{
	Default
	{
		BIO_WeaponReplacer.SpawnCategory BIO_WSCAT_PISTOL;
	}
}
